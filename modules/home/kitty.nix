# Kitty — matugen writes colors.conf here.
# Workflow: edit modules/home/kitty/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncKitty = syncDir ./kitty "$HOME/.config/kitty";
}
