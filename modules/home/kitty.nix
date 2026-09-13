# Kitty — matugen writes colors.conf here (runtime state, never synced).
# Workflow: edit modules/home/kitty/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncKitty = syncDir ./kitty "$HOME/.config/kitty" [
    "colors.conf"
  ];
}
