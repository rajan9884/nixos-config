# SwayNC config — source lives in ./swaync/, synced as MUTABLE copies.
# Mutable because matugen writes style.css here.
# Workflow: edit modules/swaync/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncSwaync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/swaync" ]; then rm "$HOME/.config/swaync"; fi
    mkdir -p "$HOME/.config/swaync"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./swaync}/" "$HOME/.config/swaync/"
  '';
}
