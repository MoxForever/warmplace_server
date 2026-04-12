{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.docker-deploy;

  githubAuthScript = pkgs.writeShellScriptBin "github-app-token" ''
    set -euo pipefail

    APP_ID="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github_app_app_id.path})"
    INSTALLATION_ID="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github_app_installation_id.path})"
    PRIVATE_KEY_FILE="${config.sops.secrets.github_app_private_key.path}"

    NOW=$(${pkgs.coreutils}/bin/date +%s)
    IAT=$((NOW - 60))
    EXP=$((NOW + 600))

    HEADER=$(${pkgs.coreutils}/bin/printf '{"alg":"RS256","typ":"JWT"}' | ${pkgs.coreutils}/bin/base64 -w0 | tr '/+' '_-' | tr -d '=')
    PAYLOAD=$(${pkgs.jq}/bin/jq -nc \
      --arg iat "$IAT" \
      --arg exp "$EXP" \
      --arg iss "$APP_ID" \
      '{iat: ($iat|tonumber), exp: ($exp|tonumber), iss: ($iss|tonumber)}' \
      | ${pkgs.coreutils}/bin/base64 -w0 | tr '/+' '_-' | tr -d '=')

    UNSIGNED="$HEADER.$PAYLOAD"

    SIGNATURE=$(printf %s "$UNSIGNED" | \
      ${pkgs.openssl}/bin/openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | \
      ${pkgs.coreutils}/bin/base64 -w0 | tr '/+' '_-' | tr -d '=')

    JWT="$UNSIGNED.$SIGNATURE"

    TOKEN=$(${pkgs.curl}/bin/curl -s -X POST \
      -H "Authorization: Bearer $JWT" \
      -H "Accept: application/vnd.github+json" \
      https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens \
      | ${pkgs.jq}/bin/jq -r .token)

    echo "$TOKEN"
  '';

in
{
  options.docker-deploy = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          repo = mkOption {
            type = types.str;
          };

          branch = mkOption {
            type = types.str;
            default = "main";
          };

          ports = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };

          volumes = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };

          path = mkOption {
            type = types.str;
            default = "/home/deploy";
          };

          dockerfile = mkOption {
            type = types.str;
            default = "Dockerfile";
          };
        };
      }
    );
  };

  config = mkIf (cfg != { }) {
    virtualisation.docker.enable = true;

    sops.secrets = {
      github_app_app_id = {
        key = "github_app/app_id";
        owner = "root";
        mode = "0400";
      };

      github_app_installation_id = {
        key = "github_app/installation_id";
        owner = "root";
        mode = "0400";
      };

      github_app_private_key = {
        key = "github_app/private_key";
        owner = "root";
        mode = "0400";
      };
    };

    environment.systemPackages = [
      githubAuthScript

      (pkgs.writeShellScriptBin "docker-update" ''
        set -euo pipefail

        if [[ $# -ne 1 ]]; then
          echo "Usage: docker-update <app-name>"
          exit 1
        fi

        APP_NAME="$1"
        SERVICE="docker-deploy-$APP_NAME.service"

        systemctl start "$SERVICE"
        systemctl status "$SERVICE" --no-pager
      '')
    ];

    systemd.services = mapAttrs' (
      name: app:
      nameValuePair "docker-deploy-${name}" {
        wantedBy = [ "multi-user.target" ];

        path = [
          pkgs.git
          pkgs.docker
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.curl
          pkgs.jq
          pkgs.openssl
        ];

        serviceConfig = {
          Type = "oneshot";
          User = "deploy";
        };

        script = ''
          set -euo pipefail

          TOKEN="$(${githubAuthScript}/bin/github-app-token)"

          REPO_URL=$(echo "${app.repo}" | sed 's#https://github.com/#https://x-access-token:'"$TOKEN"'@github.com/#')

          BASE_PATH="${app.path}"
          if [[ "$BASE_PATH" == "~" ]]; then
            BASE_PATH="$HOME"
          elif [[ "$BASE_PATH" == ~/* ]]; then
            BASE_PATH="$HOME/''${BASE_PATH#~/}"
          fi

          APP_DIR="$BASE_PATH/${name}"
          mkdir -p "$BASE_PATH"

          if [ ! -d "$APP_DIR/.git" ]; then
            ${pkgs.git}/bin/git clone \
              -b ${app.branch} \
              --single-branch \
              "$REPO_URL" \
              "$APP_DIR"
          fi

          cd "$APP_DIR"

          ${pkgs.git}/bin/git remote set-url origin "$REPO_URL"

          ${pkgs.git}/bin/git fetch origin ${app.branch}
          ${pkgs.git}/bin/git checkout ${app.branch}
          ${pkgs.git}/bin/git pull origin ${app.branch}

          if [ ! -f "$APP_DIR/${app.dockerfile}" ]; then
            echo "Dockerfile not found: $APP_DIR/${app.dockerfile}"
            exit 1
          fi

          ${pkgs.docker}/bin/docker build \
            -f "$APP_DIR/${app.dockerfile}" \
            -t ${name}:${app.branch}-latest \
            .

          if ${pkgs.docker}/bin/docker ps -a --format '{{.Names}}' | ${pkgs.gnugrep}/bin/grep -Fxq ${name}; then
            ${pkgs.docker}/bin/docker stop ${name}
            ${pkgs.docker}/bin/docker rm ${name}
          fi

          PORTS="${concatStringsSep " " (map (p: "-p " + p) app.ports)}"
          VOLUMES="${concatStringsSep " " (map (v: "-v " + v) app.volumes)}"

          ${pkgs.docker}/bin/docker run -d \
            --name ${name} \
            --add-host=host.docker.internal:host-gateway \
            --env-file .env \
            $PORTS \
            $VOLUMES \
            ${name}:${app.branch}-latest
        '';
      }
    ) cfg;
  };
}
