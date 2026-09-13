# Rofi — matugen writes colors.rasi, theme selector relinks active-*.rasi.
# All four are runtime state (excluded from sync, seeded below).
# Workflow: edit modules/home/rofi/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncRofi = syncDir ./rofi "$HOME/.config/rofi" [
    "colors.rasi"
    "active-launcher.rasi"
    "active-picker.rasi"
    "active-scripts.rasi"
  ];
  # Default theme links on fresh installs only — the theme selector owns
  # them afterwards.
  home.activation.seedRofiTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/rofi/active-launcher.rasi" ]; then
      ln -sf "$HOME/.config/rofi/themes/noro/launcher.rasi" "$HOME/.config/rofi/active-launcher.rasi"
    fi
    if [ ! -e "$HOME/.config/rofi/active-scripts.rasi" ]; then
      ln -sf "$HOME/.config/rofi/themes/noro/scripts.rasi" "$HOME/.config/rofi/active-scripts.rasi"
    fi
    if [ ! -e "$HOME/.config/rofi/active-picker.rasi" ]; then
      ln -sf "$HOME/.config/rofi/themes/noro/picker.rasi" "$HOME/.config/rofi/active-picker.rasi"
    fi
  '';
}
