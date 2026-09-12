# Zed config — source lives in ./zed/, synced as MUTABLE copies.
# Mutable because matugen writes themes/matugen.json here.
# Workflow: edit modules/zed/, `git add` it, rebuild.
{ pkgs, lib, ... }:
{
  home.activation.syncZed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/zed" ]; then rm "$HOME/.config/zed"; fi
    mkdir -p "$HOME/.config/zed"
    ${pkgs.rsync}/bin/rsync -a --chmod=u+w "${./zed}/" "$HOME/.config/zed/"
  '';
}
