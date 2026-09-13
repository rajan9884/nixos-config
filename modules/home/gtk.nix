# GTK settings — matugen writes gtk.css / gtk-dark.css here (runtime state).
# Workflow: edit modules/home/gtk-3.0|gtk-4.0/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncGtk3 = syncDir ./gtk-3.0 "$HOME/.config/gtk-3.0" [
    "gtk.css"
  ];
  home.activation.syncGtk4 = syncDir ./gtk-4.0 "$HOME/.config/gtk-4.0" [
    "gtk.css"
    "gtk-dark.css"
  ];
}
