# Matugen config + templates.
# Also creates generated-only dirs matugen writes to
# (fastfetch, helium-theme, ghostty) so first run never fails.
# Workflow: edit modules/home/matugen/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncMatugen = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/matugen" ]; then rm "$HOME/.config/matugen"; fi
    mkdir -p "$HOME/.config/matugen"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./matugen}/" "$HOME/.config/matugen/"
    mkdir -p "$HOME/.config/fastfetch" "$HOME/.config/helium-theme" "$HOME/.config/ghostty"
  '';
}
