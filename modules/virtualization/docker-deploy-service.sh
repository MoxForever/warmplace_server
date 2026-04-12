set -euo pipefail

APP_NAME=""
APP_REPO=""
APP_BRANCH=""
APP_PATH=""
APP_DOCKERFILE=""
APP_PORTS=""
APP_VOLUMES=""

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
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: docker-deploy-service --app-name <name> --repo <url> --branch <branch> --path <path> --dockerfile <file> --ports <csv> --volumes <csv>" >&2
      exit 1
      ;;
  esac
done

: "${APP_NAME:?Missing required --app-name}"
: "${APP_REPO:?Missing required --repo}"
: "${APP_BRANCH:?Missing required --branch}"
: "${APP_PATH:?Missing required --path}"
: "${APP_DOCKERFILE:?Missing required --dockerfile}"

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

# === CHECK CURRENT RUNNING CONTAINER ===
CURRENT_HASH=""

if docker ps -a --format '{{.Names}}' | grep -Fxq "$APP_NAME"; then
  CURRENT_HASH=$(docker inspect "$APP_NAME" \
    --format='{{ index .Config.Labels "git.commit" }}' 2>/dev/null || true)
fi

if [[ "$CURRENT_HASH" == "$GIT_HASH" && -n "$CURRENT_HASH" ]]; then
  echo "No changes detected (git commit: $GIT_HASH) → skipping deploy"
  exit 0
fi

# === CHECK DOCKERFILE ===
if [ ! -f "$APP_DIR/$APP_DOCKERFILE" ]; then
  echo "Dockerfile not found: $APP_DIR/$APP_DOCKERFILE"
  exit 1
fi

# === BUILD IMAGE ===
docker build \
  -f "$APP_DIR/$APP_DOCKERFILE" \
  --build-arg GIT_COMMIT="$GIT_HASH" \
  -t "$APP_NAME:$APP_BRANCH-latest" \
  .

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
  --env-file .env \
  "${PORT_ARGS[@]}" \
  "${VOLUME_ARGS[@]}" \
  "$APP_NAME:$APP_BRANCH-latest"