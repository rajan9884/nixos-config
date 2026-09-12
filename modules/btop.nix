# btop config — source lives in ./btop/, synced as MUTABLE copies.
# Mutable because matugen writes themes/matugen.theme here.
# Workflow: edit modules/btop/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncBtop = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/btop" ]; then rm "$HOME/.config/btop"; fi
    mkdir -p "$HOME/.config/btop"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./btop}/" "$HOME/.config/btop/"
  '';
}
