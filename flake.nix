{
  description = "NixOS + Hyprland — reproducible desktop (repo: ~/nixos-config, wallpapers: ~/wallpapers)";

  inputs = {
    # Unstable gives Hyprland 0.55+ (Lua API), awww, matugen, satty, etc.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Cross-distro wallpaper collection (sibling checkout ~/wallpapers).
    # After pushing: url = "github:rajan9884/wallpapers";
    # Kept as flake input so ~/.local/share/wallpapers is declarative
    # instead of a 95M+ closure embedded in nixos-config itself.
    # NOTE: path: inputs must exist at `nix flake check` time;
    # if ~/wallpapers is missing, create it (or `git clone` it) first.
    wallpapers = {
      url = "path:../wallpapers";
      flake = false;
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
          # First switch on minimal install already has real ~/.config files.
          # Without this, HM activation fails AFTER building with
          # "existing file ... is in the way".
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.rajan = import ./home/rajan.nix;
        }
      ];
    };
  };
}
