# Fastfetch — static system-info config (no generated files).
# Workflow: edit modules/home/fastfetch/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncFastfetch = syncDir ./fastfetch "$HOME/.config/fastfetch" [ ];
}
