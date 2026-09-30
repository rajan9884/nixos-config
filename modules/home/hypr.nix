# Hyprland — matugen writes colors.conf/colors.lua/hyprlock-colors.conf here.
# All three are runtime state (excluded from sync) so rebuilds/boots never
# restore stale colors. theme.lua is a static wallpaper-driven decoration
# block (versioned). See lib/sync-dir.nix.
# Workflow: edit modules/home/hypr/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncHypr = syncDir ./hypr "$HOME/.config/hypr" [
    "/colors.conf"
    "/colors.lua"
    "/hyprlock-colors.conf"
  ];
}
