{
  config,
  lib,
  pkgs,
  stateVersion,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = false;
    grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  networking.hostName = "warmplace";
  networking.networkmanager.enable = true;

  time.timeZone = "UTC";

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "yes";
    };
  };
  services.qemuGuest.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.fish.enable = true;

  users.users.root = {
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxoIuwEmcH0zAmBkYbGUeWgcoXcz0VEMI5/wT3ydOx4"
    ];
  };

  system.stateVersion = stateVersion;
}
