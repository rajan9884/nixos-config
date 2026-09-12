# Neovim — lazy.nvim writes lockfile/state here.
# Workflow: edit modules/home/nvim/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncNvim = syncDir ./nvim "$HOME/.config/nvim";
}
