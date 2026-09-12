# Rofi config — source lives in ./rofi/, synced as MUTABLE copies.
# Mutable because matugen writes colors.rasi and the theme selector relinks
# active-*.rasi here. Workflow: edit modules/rofi/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncRofi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/rofi" ]; then rm "$HOME/.config/rofi"; fi
    mkdir -p "$HOME/.config/rofi"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./rofi}/" "$HOME/.config/rofi/"
  '';
}
