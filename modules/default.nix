{ ... }:

{
  imports = [
    ./base.nix
    ./database.nix
    ./netdata.nix
    ./network.nix
    ./secrets.nix
    ./ssh.nix
    ./terminal.nix
    ./virtualization
  ];
}
