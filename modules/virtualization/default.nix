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
    ${pkgs.bash}/bin/bash ${./github-app-token.sh} \
      --app-id-file "${config.sops.secrets.github_app_app_id.path}" \
      --installation-id-file "${config.sops.secrets.github_app_installation_id.path}" \
      --private-key-file "${config.sops.secrets.github_app_private_key.path}"
  '';

  dockerUpdateScript = pkgs.writeShellScriptBin "docker-update" (
    builtins.readFile ./docker-update.sh
  );

in
{
  imports = [
    ./utils.nix
  ];
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
    _module.args = {
      inherit dockerUpdateScript;
    };

    systemd.services = mapAttrs' (
      name: app:
      nameValuePair "docker-deploy@${name}" {
        wantedBy = [ "multi-user.target" ];

        path = [
          pkgs.git
          pkgs.docker
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.curl
          pkgs.jq
          pkgs.openssl
          githubAuthScript
        ];

        serviceConfig = {
          Type = "oneshot";
          User = "deploy";
        };

        script = ''
          ${pkgs.bash}/bin/bash ${./docker-deploy-service.sh} \
            --app-name "${name}" \
            --repo "${app.repo}" \
            --branch "${app.branch}" \
            --path "${app.path}" \
            --dockerfile "${app.dockerfile}" \
            --ports "${concatStringsSep "," app.ports}" \
            --volumes "${concatStringsSep "," app.volumes}" \
            --env-file "${config.sops.secrets."docker_env_${name}".path}"
        '';
      }
    ) cfg;
  };
}
