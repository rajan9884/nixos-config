# SwayNC — matugen writes style.css here (full generated file, runtime
# state, excluded via anchored pattern so only the top level is skipped).
# Workflow: edit modules/home/swaync/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncSwaync = syncDir ./swaync "$HOME/.config/swaync" [
    "/style.css"
  ];
}
