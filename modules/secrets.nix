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

  system.activationScripts.deploySshConfig.text = ''
    install -d -m 0700 -o deploy -g deploy /home/deploy/.ssh
    install -m 0644 -o deploy -g deploy ${pkgs.writeText "ssh-config" ''
      Host github.com
        IdentityFile /run/secrets/deploy_github_ssh_key
    ''} /home/deploy/.ssh/config
  '';
}
