# Hyprland — theme switching relinks files, matugen writes colors.* here.
# Workflow: edit modules/home/hypr/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncHypr = syncDir ./hypr "$HOME/.config/hypr";
}
