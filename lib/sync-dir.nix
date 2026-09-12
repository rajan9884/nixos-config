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
#   in { home.activation.syncHypr = syncDir ./hypr "$HOME/.config/hypr"; }
{ pkgs, lib }:
src: dest:
lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  if [ -L "${dest}" ]; then rm "${dest}"; fi
  mkdir -p "${dest}"
  ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${src}/" "${dest}/"
''
