{
  description = "NixOS + Hyprland — reproducible desktop (lives in /etc/nixos, app configs in ./modules)";

  inputs = {
    # Unstable gives Hyprland 0.55+ (Lua API), awww, matugen, satty, etc.
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
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # First switch on minimal install already has real ~/.config files.
          # Without this, HM activation fails AFTER building with
          # "existing file ... is in the way".
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.rajan = import ./home.nix;
        }
      ];
    };
  };
}
