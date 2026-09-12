{
  description = "NixOS + Hyprland — reproducible desktop (repo: ~/nixos-config, wallpapers: ~/wallpapers)";
  inputs = {
    # Unstable gives Hyprland 0.55+ (Lua API), awww, matugen, satty, etc.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # NOTE: wallpapers intentionally NOT a flake input — ~/wallpapers is
    # symlinked at activation (modules/home/wallpapers.nix), so 95M+ never
    # enters /nix/store. Clone it separately (see README + ~/wallpapers).
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
