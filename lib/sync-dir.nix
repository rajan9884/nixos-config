# lib/sync-dir.nix — single helper for mutable app-config sync.
#
# Why mutable rsync instead of home.file/xdg.configFile?
# Theme switching relinks files and matugen writes generated files
# (colors.css, colors.conf, colors.lua…) INTO ~/.config at runtime.
# Read-only store symlinks would break that. So we rsync vendored
# files as writable copies.
#
# Usage in modules/home/<app>.nix:
#   { pkgs, lib, ... }:
#   let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
#   in { home.activation.syncHypr = syncDir ./hypr "$HOME/.config/hypr" []; }
#
# `excludes` is a list of rsync filter patterns for RUNTIME state that must
# never be overwritten with repo copies: matugen outputs (colors.conf,
# gtk.css, …) and theme-selector symlinks (active-*.rasi, theme.lua, …).
# Overwriting those is the "stale theme after every boot/rebuild" bug —
# the live palette gets replaced by whatever was committed, until the next
# wallpaper switch regenerates it. Patterns without a `/` match the
# basename at any depth; prefix with `/` to anchor to the top level
# (e.g. `/style.css` for swaync without touching deeper style files).
{ pkgs, lib }:
src: dest: excludes:
lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  if [ -L "${dest}" ]; then rm "${dest}"; fi
  mkdir -p "${dest}"
  ${pkgs.rsync}/bin/rsync -a --chmod=u+w${lib.concatMapStrings (e: " --exclude='${e}'") excludes} "${src}/" "${dest}/"
''
