{
  config,
  lib,
  pkgs,
  stateVersion,
  ...
}:

{
  boot.loader = {
    systemd-boot.enable = false;
    grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  networking.firewall.enable = true;
  networking.hostName = "warmplace";
  networking.networkmanager.enable = true;

  time.timeZone = "UTC";

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

  services.qemuGuest.enable = true;
  system.stateVersion = stateVersion;
}
