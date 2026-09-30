# Wallpapers — sibling ~/wallpapers repo, FLATTEN-COPIED (not symlinked, not nested).
#
# Layout contract (flat):
#   ~/wallpapers/                        # upstream repo (any nesting: Wallpaper/*.jpg,
#                                        #   glass/material/... subdirs, whatever)
#     -> $HOME/.local/share/wallpapers/  # FLAT: *.jpg/*.jpeg/*.png/*.webp directly
#                                        #   inside, NO subdirectories.
#
# Why flatten-copy instead of `ln -sfn ~/wallpapers ~/.local/share/wallpapers`?
# The old symlink exposed the repo's internal layout (Wallpaper/noro/optimized
# subdirs), so every consumer had to guess the nesting depth — pickers reading
# ~/.local/share/wallpapers/*.jpg found nothing, while `noro/nord-wallpaper.jpg`
# broke the moment upstream went flat. A flattened copy means every tool uses
# ONE path: find $DEST -maxdepth 1 -type f.
#
# Why copy instead of `xdg.dataFile.source = inputs.wallpapers`?
# A path/flake input copies 95M+ into /nix/store on EVERY rebuild.
# A plain `cp` in activation costs 0 store bytes and stays usable on
# non-NixOS distros (see ~/wallpapers/install.sh --flat).
#
# Fresh install order:
#   1. git clone https://github.com/rajan9884/wallpapers.git ~/wallpapers
#   2. rebuild — this activation flatten-copies ~/wallpapers -> DEST.
#      Re-run any time with:  wallpapers-sync   (also in ~/.local/bin)
{ pkgs, lib, ... }:
{
  home.activation.syncWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SRC="$HOME/wallpapers"
    DEST="$HOME/.local/share/wallpapers"
    # Legacy layout was a symlink DEST -> ~/wallpapers. Remove it so DEST
    # becomes a real flat directory.
    if [ -L "$DEST" ]; then rm -f "$DEST"; fi
    mkdir -p "$DEST"
    if [ -d "$SRC" ]; then
      # Drop legacy nested dirs from the old per-theme layout
      # (Wallpaper/, noro/, material/, retro/, modern/, glass/, optimized/).
      # DEST is files-only by contract; any leftover subdir is stale.
      ${pkgs.findutils}/bin/find "$DEST" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
      ${pkgs.findutils}/bin/find "$DEST" -mindepth 1 -maxdepth 1 -type l -exec rm -f {} + 2>/dev/null || true
      # Flatten-copy every image under ~/wallpapers (any depth, .git excluded).
      # Name collisions (same basename in two subdirs) get a parent-dir suffix,
      # then a numeric suffix — no silent overwrites of different images.
      ${pkgs.findutils}/bin/find "$SRC" -path "$SRC/.git" -prune -o -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 \
      | while IFS= read -r -d ''' src; do
          base="$(basename "$src")"
          dest="$DEST/$base"
          if [ -e "$dest" ] && ! ${pkgs.diffutils}/bin/cmp -s "$src" "$dest"; then
            stem="''${base%.*}"
            ext="''${base##*.}"
            if [ "$stem" = "$ext" ]; then ext=""; else ext=".$ext"; fi
            parent="$(basename "$(dirname "$src")")"
            dest="$DEST/''${stem}_''${parent}''${ext}"
            n=1
            while [ -e "$dest" ] && ! ${pkgs.diffutils}/bin/cmp -s "$src" "$dest"; do
              n=$((n + 1))
              dest="$DEST/''${stem}_''${parent}_''${n}''${ext}"
            done
          fi
          ${pkgs.coreutils}/bin/cp -f "$src" "$dest"
        done
    else
      # Fallback: single offline image (flat) so wallpaper-init + matugen
      # never fail on a machine where ~/wallpapers hasn't been cloned yet.
      ${pkgs.coreutils}/bin/cp -f "${../../assets/fallback-wallpaper.jpg}" "$DEST/fallback-wallpaper.jpg"
    fi
    # Guarantee DEST is never empty (e.g. ~/wallpapers exists but has no
    # images yet): seed the offline fallback so matugen/waybar seeds below
    # always have a WALL to work with and the GUI comes back styled.
    if ! ${pkgs.findutils}/bin/find "$DEST" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print -quit 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q .; then
      ${pkgs.coreutils}/bin/cp -f "${../../assets/fallback-wallpaper.jpg}" "$DEST/fallback-wallpaper.jpg" || true
    fi
  '';
}
