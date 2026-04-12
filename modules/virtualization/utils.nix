{
  config,
  dockerUpdateScript,
  lib,
  ...
}:

with lib;

let
  cfg = config.docker-deploy;

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
    };

    environment.systemPackages = [
      dockerUpdateScript
    ];

    environment.etc."fish/vendor_completions.d/docker-update.fish".source = ./docker-update.fish;

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
