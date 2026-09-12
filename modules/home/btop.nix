# btop config — matugen writes themes/matugen.theme here.
# Workflow: edit modules/home/btop/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncBtop = syncDir ./btop "$HOME/.config/btop";
}
