# Hyprland — matugen writes colors.conf/colors.lua/hyprlock-colors.conf here,
# theme switching relinks theme.lua. All four are runtime state (excluded
# from sync, seeded below) so rebuilds/boots never restore stale colors or
# pin the theme back. See lib/sync-dir.nix.
# Workflow: edit modules/home/hypr/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncHypr = syncDir ./hypr "$HOME/.config/hypr" [
    "colors.conf"
    "colors.lua"
    "hyprlock-colors.conf"
    "theme.lua"
  ];
  # Default theme link on fresh installs only — the theme selector owns it
  # afterwards (theme-chain.sh / nixos-theme-apply).
  home.activation.seedHyprTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/hypr/theme.lua" ]; then
      ln -sf "$HOME/.config/hypr/themes/noro/theme.lua" "$HOME/.config/hypr/theme.lua"
    fi
  '';
}
