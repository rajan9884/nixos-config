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
    # NOTE: colors.css (matugen output), config.jsonc + style.css (theme
    # selector symlinks into themes/<name>/) are RUNTIME state — never sync
    # them from the repo. Overwriting colors.css with a committed copy is
    # exactly the "yellow bar after every reboot/rebuild" bug: the stale
    # palette replaces the live one until the next wallpaper switch
    # regenerates it. Likewise, syncing the theme links would pin the bar
    # back to the default theme on every boot, clobbering the user's pick.
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w \
      --exclude='colors.css' \
      --exclude='config.jsonc' \
      --exclude='style.css' \
      "${./waybar}/" "$HOME/.config/waybar/"

    # Seed the default (Noro) theme links on fresh installs only — the
    # theme selector owns these afterwards.
    if [ ! -e "$HOME/.config/waybar/config.jsonc" ]; then
      ln -sf "$HOME/.config/waybar/themes/noro/config.jsonc" "$HOME/.config/waybar/config.jsonc"
    fi
    if [ ! -e "$HOME/.config/waybar/style.css" ]; then
      ln -sf "$HOME/.config/waybar/themes/noro/style.css" "$HOME/.config/waybar/style.css"
    fi

    # Matugen colors fallback: style.css does `@import "colors.css"` and
    # waybar loses all theming if that file is missing. wallpaper-init
    # normally creates it on first login, but if that unit hasn't run yet,
    # every waybar start is unstyled. Generate it here ONLY when missing —
    # never overwrite a live palette. Prefer the current wallpaper so the
    # bar matches the screen; fall back to the default Noro wallpaper.
    if [ ! -f "$HOME/.config/waybar/colors.css" ]; then
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
      # Last resort: a static neutral-dark palette. A real palette keeps
      # the bar styled; an EMPTY file would leave every @variable undefined
      # (unstyled/yellowish bar), so never touch an empty file into place.
      if [ ! -s "$HOME/.config/waybar/colors.css" ]; then
        cat > "$HOME/.config/waybar/colors.css" <<'COLORS_EOF'
@define-color primary #b9c3ff;
@define-color on_primary #1e2b66;
@define-color primary_container #9aa7ea;
@define-color on_primary_container #091955;
@define-color secondary #c1c5e3;
@define-color on_secondary #2a2f47;
@define-color secondary_container #41455e;
@define-color on_secondary_container #dbdefd;
@define-color tertiary #f4b1ea;
@define-color on_tertiary #4e1d4c;
@define-color tertiary_container #d696cd;
@define-color on_tertiary_container #3b0a3a;
@define-color error #ffb4ab;
@define-color on_error #690005;
@define-color error_container #93000a;
@define-color on_error_container #ffdad6;
@define-color background #131317;
@define-color on_background #e4e1e7;
@define-color surface #131317;
@define-color on_surface #e4e1e7;
@define-color surface_variant #454650;
@define-color on_surface_variant #c6c5d1;
@define-color outline #90909b;
@define-color shadow #000000;
@define-color inverse_surface #e4e1e7;
@define-color inverse_on_surface #303035;
@define-color inverse_primary #4d5a98;
COLORS_EOF
      fi
    fi

    # Single-bar guarantee after every switch (kills any stacked strays).
    ${pkgs.systemd}/bin/systemctl --user restart waybar.service 2>/dev/null || true
  '';
}
