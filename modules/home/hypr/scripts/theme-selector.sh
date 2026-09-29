#!/usr/bin/env bash
# Flat wallpaper store: ~/.local/share/wallpapers (files only, wallpapers-sync).

WALLPAPER_DIR="$HOME/.local/share/wallpapers"

[ -d "$WALLPAPER_DIR" ] || {
    notify-send "Wallpaper Error" "No wallpaper directory found (run wallpapers-sync)" -u critical
    exit 1
}

# List images from the flat store, pass to rofi, and get selection
SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) -printf "%p\n" 2>/dev/null | sort | rofi -dmenu -i -p "Select Wallpaper" -theme ~/.config/rofi/theme.rasi)

if [ -n "$SELECTED" ]; then
    # Call the existing swww-all.sh script which runs matugen for colors
    ~/.config/hypr/scripts/swww-all.sh "$SELECTED"
fi
