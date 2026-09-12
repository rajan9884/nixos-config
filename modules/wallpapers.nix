# Wallpapers — source lives in ./wallpapers/, exposed as read-only store symlinks.
# Never mutated (pickers only read), so no mutable copy needed.
{ ... }:
{
  xdg.dataFile."wallpapers".source = ./wallpapers;
}
