{
  description = "Warmplace NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      stateVersion = "25.11";
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.warmplace = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit stateVersion;
        };
        modules = [
          ./modules
          ./projects
          ./users.nix
          ./hardware-configuration.nix
        ];
      };
    };
}
