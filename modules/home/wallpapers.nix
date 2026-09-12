# Wallpapers — from flake input `wallpapers` (sibling ~/wallpapers repo),
# NOT vendored in nixos-config (was 95M+ working tree, 183M with history).
# Pickers only read, so a read-only store symlink is enough (never mutated).
#
# Fresh install needs ~/wallpapers present for `path:../wallpapers`:
#   git clone <remote>/wallpapers.git ~/wallpapers
#   # or: ~/wallpapers/install.sh  (any distro, no nix needed)
# assets/fallback-wallpaper.jpg guarantees wallpaper-init still finds
# noro/nord-wallpaper.jpg even if the input is ever empty.
{ inputs, ... }:
{
  xdg.dataFile."wallpapers".source = inputs.wallpapers;
}
