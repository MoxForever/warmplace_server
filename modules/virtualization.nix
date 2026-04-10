{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.docker-deploy;
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

          path = mkOption {
            type = types.str;
            default = "/opt";
          };
        };
      }
    );
  };

  config = mkIf (cfg != { }) {
    virtualisation.docker = {
      enable = true;
      extraOptions = "--add-host=host.docker.internal:host-gateway";
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "docker-update" ''
        #!/usr/bin/env bash
        set -euo pipefail

        if [[ $# -ne 1 ]]; then
          echo "Usage: docker-update <app-name>"
          exit 1
        fi

        APP_NAME="$1"
        SERVICE="docker-deploy-$APP_NAME.service"

        if ! ${pkgs.systemd}/bin/systemctl list-unit-files "$SERVICE" --no-legend | ${pkgs.gnugrep}/bin/grep -q "$SERVICE"; then
          echo "Unknown app: $APP_NAME"
          echo "Available apps: ${concatStringsSep " " (attrNames cfg)}"
          exit 1
        fi

        ${pkgs.systemd}/bin/systemctl start "$SERVICE"
        ${pkgs.systemd}/bin/systemctl status "$SERVICE" --no-pager
      '')
    ];

    systemd.services = mapAttrs' (
      name: app:
      nameValuePair "docker-deploy-${name}" {
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          User = "deploy";
        };

        script = ''
          #!/usr/bin/env bash
          set -e

          # Skip deployment until deploy user can authenticate to GitHub over SSH.
          SSH_TEST_OUTPUT="$(${pkgs.coreutils}/bin/timeout 10 ${pkgs.openssh}/bin/ssh -T -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new git@github.com 2>&1 || true)"
          if ! echo "$SSH_TEST_OUTPUT" | ${pkgs.gnugrep}/bin/grep -q "successfully authenticated"; then
            echo "GitHub SSH auth is not ready, skipping docker-deploy-${name}"
            exit 0
          fi

          APP_DIR="${app.path}/${name}"

          if [ ! -d "$APP_DIR/.git" ]; then
            ${pkgs.git}/bin/git clone \
              -b ${app.branch} \
              --single-branch \
              ${app.repo} \
              "$APP_DIR"
          fi

          cd "$APP_DIR"

          ${pkgs.git}/bin/git fetch origin ${app.branch}
          ${pkgs.git}/bin/git checkout ${app.branch}
          ${pkgs.git}/bin/git pull origin ${app.branch}

          ${pkgs.docker}/bin/docker build -t ${name} .

          ${pkgs.docker}/bin/docker stop ${name}
          ${pkgs.docker}/bin/docker rm ${name}

          PORTS="${concatStringsSep " " (map (p: "-p " + p) app.ports)}"

          ${pkgs.docker}/bin/docker run -d \
            --name ${name} \
            $PORTS \
            ${name}
        '';
      }
    ) cfg;
  };
}
