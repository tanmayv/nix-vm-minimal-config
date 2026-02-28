{
  description = "Minimal NixOS VM flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      commonModules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.tanmay = import ./home.nix;
          # home-manager.users.tanmayvijay = import ./home.nix;
          # home-manager.users.tanmayvijay_google_com = import ./home.nix;
        }
      ];
    in
    {
      nixosConfigurations = {
        nixos-vm-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = commonModules;
        };
        nixos-vm-x86_64 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules;
        };
        nixos-gce-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules ++ [
            ./vm.nix
          ];
        };
        nixos-gce-builder = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules ++ [
            ./builder.nix
          ];
        };
        # Default to aarch64 for backward compatibility with update.sh
        nixos-vm = self.nixosConfigurations.nixos-vm-aarch64;
      };
    };
}
