# Rofi — matugen writes colors.rasi here (runtime state, excluded from sync).
# Launcher/picker/scripts styles are static versioned files.
# Workflow: edit modules/home/rofi/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncRofi = syncDir ./rofi "$HOME/.config/rofi" [
    "/colors.rasi"
  ];
}
