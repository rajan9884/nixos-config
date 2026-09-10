{
  description = "NixOS + Hyprland — port of Arch dotfiles (~/dotfiles)";

  inputs = {
    # Unstable gives Hyprland 0.55+ (Lua API), awww, matugen, satty, etc.
    # Pin to a commit after first successful build if you want reproducibility.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/laptop/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.rajan = import ./home/rajan.nix;
        }
      ];
    };
  };
}
