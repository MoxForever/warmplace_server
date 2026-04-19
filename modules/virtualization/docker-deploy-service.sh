set -euo pipefail

APP_NAME=""
APP_REPO=""
APP_BRANCH=""
APP_PATH=""
APP_DOCKERFILE=""
APP_PORTS=""
APP_VOLUMES=""
APP_ENV_FILE=""
FORCE_DEPLOY="false"

NORMALIZED_ENV_FILE=""

normalize_env_file() {
  local src_file="$1"
  local dst_file="$2"

  : > "$dst_file"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"

    # Keep comments and empty lines out of Docker env-file input.
    if [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    line="$(echo "$line" | sed -E 's/^[[:space:]]*export[[:space:]]+//')"

    if [[ "$line" != *=* ]]; then
      continue
    fi

    local key="${line%%=*}"
    local value="${line#*=}"

    key="$(echo "$key" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

    if [[ -z "$key" ]]; then
      continue
    fi

    if [[ "$value" =~ ^\"(.*)\"$ ]]; then
      value="${BASH_REMATCH[1]}"
      value="${value//\\\"/\"}"
      value="${value//\\\\/\\}"
    elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
      value="${BASH_REMATCH[1]}"
    fi

    printf '%s=%s\n' "$key" "$value" >> "$dst_file"
  done < "$src_file"
}

require_value() {
  local arg_name="$1"
  if [[ $# -lt 2 || "$2" == --* ]]; then
    echo "Missing value for $arg_name" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      require_value "$1" "$2"
      APP_NAME="$2"
      shift 2
      ;;
    --repo)
      require_value "$1" "$2"
      APP_REPO="$2"
      shift 2
      ;;
    --branch)
      require_value "$1" "$2"
      APP_BRANCH="$2"
      shift 2
      ;;
    --path)
      require_value "$1" "$2"
      APP_PATH="$2"
      shift 2
      ;;
    --dockerfile)
      require_value "$1" "$2"
      APP_DOCKERFILE="$2"
      shift 2
      ;;
    --ports)
      require_value "$1" "$2"
      APP_PORTS="$2"
      shift 2
      ;;
    --volumes)
      require_value "$1" "$2"
      APP_VOLUMES="$2"
      shift 2
      ;;
    --env-file)
      require_value "$1" "$2"
      APP_ENV_FILE="$2"
      shift 2
      ;;
    --force)
      FORCE_DEPLOY="true"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: docker-deploy-service --app-name <name> --repo <url> --branch <branch> --path <path> --dockerfile <file> --ports <csv> --volumes <csv> --env-file <path> [--force]" >&2
      exit 1
      ;;
  esac
done

: "${APP_NAME:?Missing required --app-name}"
: "${APP_REPO:?Missing required --repo}"
: "${APP_BRANCH:?Missing required --branch}"
: "${APP_PATH:?Missing required --path}"
: "${APP_DOCKERFILE:?Missing required --dockerfile}"
: "${APP_ENV_FILE:?Missing required --env-file}"

if [[ ! -f "$APP_ENV_FILE" ]]; then
  echo "Env file not found: $APP_ENV_FILE" >&2
  exit 1
fi

NORMALIZED_ENV_FILE="$(mktemp /tmp/${APP_NAME}.env.XXXXXX)"
trap '[[ -n "$NORMALIZED_ENV_FILE" ]] && rm -f "$NORMALIZED_ENV_FILE"' EXIT

normalize_env_file "$APP_ENV_FILE" "$NORMALIZED_ENV_FILE"

FORCE_MARKER="/run/docker-deploy-force/$APP_NAME"
if [[ -f "$FORCE_MARKER" ]]; then
  FORCE_DEPLOY="true"
  rm -f "$FORCE_MARKER" || true
fi

TOKEN="$(github-app-token)"

REPO_URL=$(echo "$APP_REPO" | sed 's#https://github.com/#https://x-access-token:'"$TOKEN"'@github.com/#')

BASE_PATH="$APP_PATH"
if [[ "$BASE_PATH" == "~" ]]; then
  BASE_PATH="$HOME"
elif [[ "$BASE_PATH" == ~/* ]]; then
  BASE_PATH="$HOME/${BASE_PATH#~/}"
fi

APP_DIR="$BASE_PATH/$APP_NAME"
mkdir -p "$BASE_PATH"

# clone if not exists
if [ ! -d "$APP_DIR/.git" ]; then
  git clone \
    -b "$APP_BRANCH" \
    --single-branch \
    "$REPO_URL" \
    "$APP_DIR"
fi

cd "$APP_DIR"

git remote set-url origin "$REPO_URL"

git fetch origin "$APP_BRANCH"
git checkout "$APP_BRANCH"
git pull origin "$APP_BRANCH"

# === GIT HASH ===
GIT_HASH=$(git rev-parse HEAD)

DEPLOYED_HASH_FILE="$APP_DIR/.docker-deploy-commit"
PREVIOUS_DEPLOYED_HASH=""
if [ -f "$DEPLOYED_HASH_FILE" ]; then
  PREVIOUS_DEPLOYED_HASH=$(cat "$DEPLOYED_HASH_FILE")
fi

if [[ "$FORCE_DEPLOY" != "true" && "$PREVIOUS_DEPLOYED_HASH" == "$GIT_HASH" && -n "$PREVIOUS_DEPLOYED_HASH" ]]; then
  echo "No changes detected (git commit: $GIT_HASH) -> skipping deploy"
  exit 0
fi

# === CHECK CURRENT IMAGE SHA ===
CURRENT_IMAGE_SHA=""
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -Fxq "$APP_NAME:$APP_BRANCH-latest"; then
  CURRENT_IMAGE_SHA=$(docker image inspect "$APP_NAME:$APP_BRANCH-latest" --format='{{.ID}}' 2>/dev/null || true)
fi

# === BUILD IMAGE ===
docker build \
  -f "$APP_DIR/$APP_DOCKERFILE" \
  --build-arg GIT_COMMIT="$GIT_HASH" \
  -t "$APP_NAME:$APP_BRANCH-latest" \
  . > /tmp/docker-build-$APP_NAME.log 2>&1

# === CHECK NEW IMAGE SHA ===
NEW_IMAGE_SHA=$(docker image inspect "$APP_NAME:$APP_BRANCH-latest" --format='{{.ID}}')

# === SKIP IF IMAGE UNCHANGED ===
if [[ "$FORCE_DEPLOY" != "true" && "$CURRENT_IMAGE_SHA" == "$NEW_IMAGE_SHA" && -n "$CURRENT_IMAGE_SHA" ]]; then
  echo "Image unchanged (SHA: ${NEW_IMAGE_SHA:0:19}...) → skipping container restart"
  exit 0
fi

# === STOP OLD CONTAINER ===
if docker ps -a --format '{{.Names}}' | grep -Fxq "$APP_NAME"; then
  docker stop "$APP_NAME" || true
  docker rm "$APP_NAME" || true
fi

# === PORTS ===
PORT_ARGS=()
if [[ -n "${APP_PORTS:-}" ]]; then
  IFS=',' read -r -a PORTS <<< "$APP_PORTS"
  for p in "${PORTS[@]}"; do
    [[ -n "$p" ]] && PORT_ARGS+=("-p" "$p")
  done
fi

# === VOLUMES ===
VOLUME_ARGS=()
if [[ -n "${APP_VOLUMES:-}" ]]; then
  IFS=',' read -r -a VOLUMES <<< "$APP_VOLUMES"
  for v in "${VOLUMES[@]}"; do
    [[ -n "$v" ]] && VOLUME_ARGS+=("-v" "$v")
  done
fi

# === RUN NEW CONTAINER ===
docker run -d \
  --name "$APP_NAME" \
  --add-host=host.docker.internal:host-gateway \
  --env-file "$NORMALIZED_ENV_FILE" \
  "${PORT_ARGS[@]}" \
  "${VOLUME_ARGS[@]}" \
  "$APP_NAME:$APP_BRANCH-latest"

echo "$GIT_HASH" > "$DEPLOYED_HASH_FILE"