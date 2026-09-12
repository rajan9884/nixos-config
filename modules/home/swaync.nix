# SwayNC — matugen writes style.css here.
# Workflow: edit modules/home/swaync/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncSwaync = syncDir ./swaync "$HOME/.config/swaync";
}
