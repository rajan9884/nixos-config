# Neovim — lazy.nvim writes lockfile/state here; matugen writes
# lua/matugen-colors.lua (already untracked; excluded as insurance).
# Workflow: edit modules/home/nvim/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncNvim = syncDir ./nvim "$HOME/.config/nvim" [
    "lua/matugen-colors.lua"
  ];
}
