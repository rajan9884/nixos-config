# Wallpapers — sibling ~/wallpapers repo, linked (NOT copied through /nix/store).
#
# Why not `xdg.dataFile.source = inputs.wallpapers`?
# A path/flake input would copy 95M+ into /nix/store on EVERY rebuild —
# the exact bloat we extracted wallpapers to avoid. A symlink costs 0 bytes
# and keeps ~/wallpapers usable on non-NixOS distros via install.sh.
#
# Fresh install order:
#   1. git clone <remote>/wallpapers.git ~/wallpapers   (before first switch
#      ideally — otherwise the fallback single-image dir below is used and
#      replaced on the next rebuild after cloning)
#   2. rebuild — this activation links ~/.local/share/wallpapers -> ~/wallpapers
{ pkgs, lib, ... }:
{
  home.activation.linkWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "$HOME/wallpapers" ]; then
      rm -rf "$HOME/.local/share/wallpapers"
      mkdir -p "$HOME/.local/share"
      ln -sfn "$HOME/wallpapers" "$HOME/.local/share/wallpapers"
    else
      # Fallback: single offline image so wallpaper-init + matugen never fail
      # on a machine where ~/wallpapers hasn't been cloned yet.
      mkdir -p "$HOME/.local/share/wallpapers/noro"
      ${pkgs.coreutils}/bin/cp -f "${../../assets/fallback-wallpaper.jpg}" "$HOME/.local/share/wallpapers/noro/nord-wallpaper.jpg"
    fi
  '';
}
