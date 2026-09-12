# Kitty config — source lives in ./kitty/, synced as MUTABLE copies.
# Mutable because matugen writes colors.conf here.
# Workflow: edit modules/kitty/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncKitty = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/kitty" ]; then rm "$HOME/.config/kitty"; fi
    mkdir -p "$HOME/.config/kitty"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./kitty}/" "$HOME/.config/kitty/"
  '';
}
