# Foot — matugen writes colors.ini here (runtime state, never synced).
# Workflow: edit modules/home/foot/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncFoot = syncDir ./foot "$HOME/.config/foot" [
    "/colors.ini"
  ];
}
