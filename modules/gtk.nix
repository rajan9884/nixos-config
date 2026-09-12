# GTK settings — sources live in ./gtk-3.0/ and ./gtk-4.0/, synced as MUTABLE copies.
# Mutable because matugen writes gtk.css / gtk-dark.css here.
# Workflow: edit modules/gtk-*/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncGtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/gtk-3.0" ]; then rm "$HOME/.config/gtk-3.0"; fi
    mkdir -p "$HOME/.config/gtk-3.0"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./gtk-3.0}/" "$HOME/.config/gtk-3.0/"
    if [ -L "$HOME/.config/gtk-4.0" ]; then rm "$HOME/.config/gtk-4.0"; fi
    mkdir -p "$HOME/.config/gtk-4.0"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./gtk-4.0}/" "$HOME/.config/gtk-4.0/"
  '';
}
