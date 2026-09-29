#!/usr/bin/env bash
# Prefer the NixOS wallpaper store, fallback to the theme dir
WALL_DIR="$HOME/.local/share/wallpapers"
[[ -d "$WALL_DIR" ]] || WALL_DIR="$HOME/.config/theme/current"
THUMB_DIR="/tmp/wall_thumbs"
LOOKUP_FILE="/tmp/wall_lookup.json"
SCRIPT_PATH="$HOME/.config/rofi/wall.sh"
selected="$1"

mkdir -p "$THUMB_DIR"

if [[ -n "$selected" ]]; then
    cleaned=$(jq -r --arg key "$selected" '.[$key] // empty' "$LOOKUP_FILE")
    if [[ -z "$cleaned" ]]; then
        echo "Could not resolve: $selected"
        exit 1
    fi
    full_path="${WALL_DIR}/${cleaned}"
    nohup "$HOME/.config/hypr/scripts/swww-all.sh" "$full_path" >/dev/null 2>&1 &
    dconf write /org/gnome/desktop/interface/icon-theme "'Papirus'" 2>/dev/null || true
else
    pairs=()
    # Flat store: files directly in WALL_DIR (wallpapers-sync). maxdepth 2
    # keeps back-compat with the old nested layout (Wallpaper/, noro/, …).
    while IFS= read -r -d '' f; do
        base=$(basename "$f")
        rel="${f#$WALL_DIR/}"  # flat store: == $base; keeps legacy subdirs working
        name_part="${base%.*}"
        pretty=$(echo "$name_part" | tr '_-' '  ' | sed -e "s/\b\(.\)/\u\1/g" -e 's/ ([0-9]\+)$//')
        pairs+=("$pretty" "$rel")

        thumb="${THUMB_DIR}/${base}.png"
        if [[ ! -e "$thumb" || "$f" -nt "$thumb" ]]; then
            magick "$f" -resize 300x300^ -gravity center -extent 300x300 \
                \( -size 300x300 xc:none -draw 'roundrectangle 0,0,299,299,30,30' \) \
                -alpha off -compose CopyOpacity -composite \
                -strip "$thumb" 2>/dev/null
        fi

        icon_path="$thumb"
        [[ -e "$icon_path" ]] || icon_path="$f"

        printf '%s\0icon\x1f%s\n' "$pretty" "$icon_path"
    done < <(find "$WALL_DIR" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 2>/dev/null | sort -z)

    jq -n '
        def pairs2obj(a): reduce range(0; a|length; 2) as $i ({}; . + {(a[$i]): a[$i+1]});
        pairs2obj($ARGS.positional)
    ' --args "${pairs[@]}" > "$LOOKUP_FILE"

    rofi -show wallpaper -modes "wallpaper:$SCRIPT_PATH" -p '🖼  Wallpaper' -show-icons \
        -theme "$HOME/.config/rofi/wallpaper.rasi" \
        -theme-str 'entry { enabled: false; }'
fi
