# Rofimoji themes — source lives in ./rofimoji/, exposed as read-only store symlinks.
{ ... }:
{
  xdg.dataFile."rofimoji/themes".source = ./rofimoji/themes;
}
