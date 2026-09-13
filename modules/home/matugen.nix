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

  # Regenerate every matugen palette when any key output is missing — a
  # single `matugen image` run rewrites them all at once. The per-app syncs
  # above deliberately EXCLUDE these files (syncing repo copies would
  # restore stale palettes on every boot/rebuild), so without this step a
  # fresh install would leave kitty/rofi/hyprlock/etc. unthemed until the
  # first manual wallpaper switch.
  home.activation.seedMatugenColors = lib.hm.dag.entryAfter [ "writeBoundary" "syncMatugen" ] ''
    if [ ! -s "$HOME/.config/waybar/colors.css" ] || \
       [ ! -s "$HOME/.config/kitty/colors.conf" ] || \
       [ ! -s "$HOME/.config/rofi/colors.rasi" ] || \
       [ ! -s "$HOME/.config/hypr/colors.conf" ] || \
       [ ! -s "$HOME/.config/hypr/colors.lua" ] || \
       [ ! -s "$HOME/.config/hypr/hyprlock-colors.conf" ] || \
       [ ! -s "$HOME/.config/gtk-3.0/gtk.css" ] || \
       [ ! -s "$HOME/.config/gtk-4.0/gtk.css" ] || \
       [ ! -s "$HOME/.config/swaync/style.css" ] || \
       [ ! -s "$HOME/.config/zed/themes/matugen.json" ] || \
       [ ! -s "$HOME/.config/btop/themes/matugen.theme" ]; then
      mkdir -p "$HOME/.config/waybar" "$HOME/.config/kitty" "$HOME/.config/rofi" \
        "$HOME/.config/hypr" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" \
        "$HOME/.config/swaync" "$HOME/.config/zed/themes" "$HOME/.config/btop/themes"
      WALL=""
      if [ -f "$HOME/.cache/current-wallpaper" ]; then
        WALL="$(cat "$HOME/.cache/current-wallpaper")"
      fi
      if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
        WALL="$HOME/.local/share/wallpapers/noro/nord-wallpaper.jpg"
        if [ ! -f "$WALL" ]; then
          WALL="$(ls "$HOME"/.local/share/wallpapers/noro/*.jpg "$HOME"/.local/share/wallpapers/noro/*.jpeg 2>/dev/null | head -n1)"
        fi
      fi
      if [ -n "$WALL" ] && [ -f "$WALL" ]; then
        ${pkgs.matugen}/bin/matugen image "$WALL" --type scheme-content -c "$HOME/.config/matugen/config.toml" --source-color-index 0 || true
      fi
    fi
  '';
}
