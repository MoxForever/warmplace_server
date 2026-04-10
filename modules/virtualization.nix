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
