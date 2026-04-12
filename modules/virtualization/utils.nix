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

  dockerUpdateCompletions = pkgs.stdenv.mkDerivation {
    name = "docker-update-completions";
    src = ./docker-update.fish;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/share/fish/vendor_completions.d
      cp $src $out/share/fish/vendor_completions.d/docker-update.fish
    '';
  };

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

    programs.fish.extraCompletionPackages = [
      dockerUpdateCompletions
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
