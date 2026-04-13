{
  config,
  dockerUpdateScript,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.docker-deploy;
  dockerEnvSecrets = mapAttrs' (
    name: _:
    nameValuePair "docker_env_${name}" {
      key = "env/${name}";
      owner = "deploy";
      mode = "0400";
    }
  ) cfg;
in

{
  config = mkIf (cfg != { }) {
    virtualisation.docker.enable = true;

    sops.secrets = {
      github_app_app_id = {
        key = "github_app/app_id";
        owner = "deploy";
        mode = "0400";
      };

      github_app_installation_id = {
        key = "github_app/installation_id";
        owner = "deploy";
        mode = "0400";
      };

      github_app_private_key = {
        key = "github_app/private_key";
        owner = "deploy";
        mode = "0400";
      };
    }
    // dockerEnvSecrets;

    environment.systemPackages = [
      dockerUpdateScript
    ];

    security.sudo.extraRules = [
      {
        groups = [ "docker" ];
        commands = [
          {
            command = "${dockerUpdateScript}/bin/docker-update";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
