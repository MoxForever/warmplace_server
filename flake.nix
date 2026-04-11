{
  description = "Warmplace NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      ...
    }:
    let
      stateVersion = "25.11";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      nixosConfigurations.warmplace = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit stateVersion;
        };
        modules = [
          sops-nix.nixosModules.sops
          ./modules
          ./projects
          ./users.nix
          ./hardware-configuration.nix
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          age
          fish
          sops
          ssh-to-age
        ];

        shellHook = ''
          export EDITOR="code --wait --reuse-window --disable-extensions"
          export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
          exec fish
        '';
      };
    };
}
