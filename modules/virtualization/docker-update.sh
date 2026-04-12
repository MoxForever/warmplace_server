set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: docker-update <app-name>"
  exit 1
fi

APP_NAME="$1"
SERVICE="docker-deploy-$APP_NAME.service"

systemctl start "$SERVICE"
systemctl status "$SERVICE" --no-pager -l