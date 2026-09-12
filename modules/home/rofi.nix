# Rofi — matugen writes colors.rasi, theme selector relinks active-*.rasi.
# Workflow: edit modules/home/rofi/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncRofi = syncDir ./rofi "$HOME/.config/rofi";
}
