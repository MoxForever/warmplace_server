{ pkgs, ... }:

{
  users.users.root.shell = pkgs.fish;
  users.users.moxforever = {
    isNormalUser = true;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxoIuwEmcH0zAmBkYbGUeWgcoXcz0VEMI5/wT3ydOx4"
    ];
    extraGroups = [
      "docker"
      "wheel"
    ];
  };
  users.users.deploy = {
    isNormalUser = true;
    shell = pkgs.fish;
    home = "/home/deploy";
    createHome = true;
    extraGroups = [ "docker" ];
  };
  users.users.yaeshop = {
    isNormalUser = true;
    shell = pkgs.fish;
    home = "/home/yaeshop";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWijPjlQaRvYXxXUs30LqAz7He9wyD5wLUVckL487CR"
    ];
    createHome = true;
    extraGroups = [ "docker" ];
  }
}
