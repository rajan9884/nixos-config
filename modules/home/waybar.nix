# Waybar config — source lives in modules/home/waybar/, synced as MUTABLE copies.
# Mutable (not a store symlink) because matugen writes colors.css here and
# the theme selector relinks config.jsonc/style.css per theme.
# Workflow: edit modules/home/waybar/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  # Runs after syncMatugen so matugen's config is in place before the
  # colors.css safety net below potentially invokes matugen.
  home.activation.syncWaybar = lib.hm.dag.entryAfter [ "writeBoundary" "syncMatugen" ] ''
    if [ -L "$HOME/.config/waybar" ]; then rm "$HOME/.config/waybar"; fi
    mkdir -p "$HOME/.config/waybar"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./waybar}/" "$HOME/.config/waybar/"

    # Matugen colors fallback: style.css does `@import "colors.css"` and
    # waybar EXITS if that file is missing. wallpaper-init normally creates
    # it on first login, but if that unit hasn't run yet, every waybar start
    # crashes instantly and stacking restarts pile up. Guarantee the file
    # exists at activation using the default Noro wallpaper. swww-all.sh
    # regenerates it on every wallpaper change afterwards.
    if [ ! -f "$HOME/.config/waybar/colors.css" ]; then
      WALL="$HOME/.local/share/wallpapers/noro/nord-wallpaper.jpg"
      if [ ! -f "$WALL" ]; then
        WALL="$(ls "$HOME"/.local/share/wallpapers/noro/*.jpg "$HOME"/.local/share/wallpapers/noro/*.jpeg 2>/dev/null | head -n1)"
      fi
      if [ -n "$WALL" ] && [ -f "$WALL" ]; then
        ${pkgs.matugen}/bin/matugen image "$WALL" --type scheme-content -c "$HOME/.config/matugen/config.toml" --source-color-index 0 || true
      fi
      [ -f "$HOME/.config/waybar/colors.css" ] || : > "$HOME/.config/waybar/colors.css"
    fi

    # Single-bar guarantee after every switch (kills any stacked strays).
    ${pkgs.systemd}/bin/systemctl --user restart waybar.service 2>/dev/null || true
  '';
}
