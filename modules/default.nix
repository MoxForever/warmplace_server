{ ... }:

{
  imports = [
    ./base.nix
    ./database.nix
    ./logs.nix
    ./network.nix
    ./secrets.nix
    ./ssh.nix
    ./terminal.nix
    ./virtualization
  ];
}
