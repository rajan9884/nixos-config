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
  home.activation.seedMatugenColors = lib.hm.dag.entryAfter [ "writeBoundary" "syncMatugen" "syncWallpapers" ] ''
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
        WALL="$(cat "$HOME/.cache/current-wallpaper" || true)"
      fi
      # Flat store: ~/.local/share/wallpapers/*.jpg (no noro/ subdir).
      if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
        for cand in "$HOME/.local/share/wallpapers/nord-wallpaper.jpg" \
                     "$HOME/.local/share/wallpapers/fallback-wallpaper.jpg"; do
          if [ -f "$cand" ]; then WALL="$cand"; break; fi
        done
      fi
      # NOTE: `|| true` — HM activation runs with `set -e -o pipefail`, so
      # `find` on a missing ~/.local/share/wallpapers would otherwise abort
      # the whole activation (no GUI) before syncWallpapers ever runs.
      if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
        WALL="$(find "$HOME/.local/share/wallpapers" -maxdepth 1 -type f \
          \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n1 || true)"
      fi
      if [ -n "$WALL" ] && [ -f "$WALL" ]; then
        ${pkgs.matugen}/bin/matugen image "$WALL" --type scheme-content -c "$HOME/.config/matugen/config.toml" --source-color-index 0 || true
      fi
    fi
  '';
}
