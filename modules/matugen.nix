# Matugen config + templates — source lives in ./matugen/, synced as MUTABLE copies.
# Also creates the generated-only dirs matugen templates write to
# (fastfetch, helium-theme, ghostty) so matugen never fails on first run.
# Workflow: edit modules/matugen/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncMatugen = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/matugen" ]; then rm "$HOME/.config/matugen"; fi
    mkdir -p "$HOME/.config/matugen"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./matugen}/" "$HOME/.config/matugen/"
    mkdir -p "$HOME/.config/fastfetch" "$HOME/.config/helium-theme" "$HOME/.config/ghostty"
  '';
}
