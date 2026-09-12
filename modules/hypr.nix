# Hyprland config — source lives in ./hypr/, synced as MUTABLE copies.
# Mutable (not a store symlink) because theme switching relinks theme files
# and matugen writes generated files (colors.conf, colors.lua) into this dir.
# rsync runs without --delete: vendored files update, generated files survive.
# Workflow: edit modules/hypr/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncHypr = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/hypr" ]; then rm "$HOME/.config/hypr"; fi
    mkdir -p "$HOME/.config/hypr"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./hypr}/" "$HOME/.config/hypr/"
  '';
}
