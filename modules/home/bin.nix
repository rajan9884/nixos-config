# Helper scripts — sources live in modules/home/bin/, linked into ~/.local/bin.
# Read-only store symlinks are fine here (scripts are never mutated at runtime).
# Workflow: edit modules/home/bin/, `git add` it, rebuild.
{ ... }:
let
  scripts = [
    "build-hyprexpo"
    "capture-region"
    "capture-satty"
    "capture-screen"
    "menu-clipboard"
    "menu-emoji"
    "menu-herdr-keybindings"
    "menu-tmux-keybindings"
    "nautilus-cwd"
    "nautilus-gnome"
    "night-light-toggle"
    "nixos-menu-images"
    "nixos-theme-apply"
    "nixos-theme-switcher"
    "nixos-wallpaper-picker"
    "ocr-extract"
    "power-profiles"
    "wall-selector"
    "waybar-selector"
    "webapp-install"
    "webapp-install-prompt"
    "webapp-launch"
    "webapp-remove"
    "webapp-remove-prompt"
    "wifi-share"
    "wifi-share-prompt"
    "window-close-all"
  ];
in
{
  home.file = builtins.listToAttrs (map (name: {
    name = ".local/bin/${name}";
    value.source = ./bin + "/${name}";
  }) scripts);
}
