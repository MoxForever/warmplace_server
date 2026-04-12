set -euo pipefail

GITHUB_APP_APP_ID_FILE=""
GITHUB_APP_INSTALLATION_ID_FILE=""
GITHUB_APP_PRIVATE_KEY_FILE=""

require_value() {
  local arg_name="$1"
  if [[ $# -lt 2 || "$2" == --* ]]; then
    echo "Missing value for $arg_name" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-id-file)
      require_value "$1" "$2"
      GITHUB_APP_APP_ID_FILE="$2"
      shift 2
      ;;
    --installation-id-file)
      require_value "$1" "$2"
      GITHUB_APP_INSTALLATION_ID_FILE="$2"
      shift 2
      ;;
    --private-key-file)
      require_value "$1" "$2"
      GITHUB_APP_PRIVATE_KEY_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: github-app-token --app-id-file <file> --installation-id-file <file> --private-key-file <file>" >&2
      exit 1
      ;;
  esac
done

: "${GITHUB_APP_APP_ID_FILE:?Missing required --app-id-file}"
: "${GITHUB_APP_INSTALLATION_ID_FILE:?Missing required --installation-id-file}"
: "${GITHUB_APP_PRIVATE_KEY_FILE:?Missing required --private-key-file}"

APP_ID="$(cat "$GITHUB_APP_APP_ID_FILE")"
INSTALLATION_ID="$(cat "$GITHUB_APP_INSTALLATION_ID_FILE")"
PRIVATE_KEY_FILE="$GITHUB_APP_PRIVATE_KEY_FILE"

NOW="$(date +%s)"
IAT=$((NOW - 60))
EXP=$((NOW + 600))

HEADER="$(printf '{"alg":"RS256","typ":"JWT"}' | base64 -w0 | tr '/+' '_-' | tr -d '=')"
PAYLOAD="$(jq -nc \
  --arg iat "$IAT" \
  --arg exp "$EXP" \
  --arg iss "$APP_ID" \
  '{iat: ($iat|tonumber), exp: ($exp|tonumber), iss: ($iss|tonumber)}' \
  | base64 -w0 | tr '/+' '_-' | tr -d '=')"

UNSIGNED="$HEADER.$PAYLOAD"

SIGNATURE="$(printf %s "$UNSIGNED" | \
  openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | \
  base64 -w0 | tr '/+' '_-' | tr -d '=')"

JWT="$UNSIGNED.$SIGNATURE"

TOKEN="$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens \
  | jq -r .token)"

echo "$TOKEN"