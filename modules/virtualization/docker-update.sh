set -euo pipefail

FORCE_DEPLOY="false"
APP_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_DEPLOY="true"
      shift
      ;;
    -* )
      echo "Unknown argument: $1"
      echo "Usage: docker-update [--force] <app-name>"
      exit 1
      ;;
    *)
      if [[ -n "$APP_NAME" ]]; then
        echo "Usage: docker-update [--force] <app-name>"
        exit 1
      fi
      APP_NAME="$1"
      shift
      ;;
  esac
done

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: docker-update [--force] <app-name>"
  exit 1
fi

SERVICE="docker-deploy@$APP_NAME.service"

if [[ "$FORCE_DEPLOY" == "true" ]]; then
  mkdir -p /run/docker-deploy-force
  touch "/run/docker-deploy-force/$APP_NAME"
fi

systemctl start "$SERVICE"
systemctl status "$SERVICE" --no-pager -l