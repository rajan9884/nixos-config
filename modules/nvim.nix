# Neovim config — source lives in ./nvim/, synced as MUTABLE copies.
# Mutable because lazy.nvim writes its lockfile/state into this dir.
# Workflow: edit modules/nvim/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncNvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/nvim" ]; then rm "$HOME/.config/nvim"; fi
    mkdir -p "$HOME/.config/nvim"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./nvim}/" "$HOME/.config/nvim/"
  '';
}
