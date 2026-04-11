{ pkgs, ... }:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;

    secrets = {
      deploy_github_ssh_key = {
        owner = "deploy";
        mode = "0400";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/deploy/.ssh 0700 deploy deploy - -"
    "L+ /home/deploy/.ssh/config - - - - ${pkgs.writeText "ssh-config" ''
      Host github.com
        IdentityFile /run/secrets/deploy_github_ssh_key
    ''}"
  ];
}
