# Zed — matugen writes themes/matugen.json here (runtime state).
# Workflow: edit modules/home/zed/, `git add` it, rebuild.
{ pkgs, lib, ... }:
let syncDir = import ../../lib/sync-dir.nix { inherit pkgs lib; };
in
{
  home.activation.syncZed = syncDir ./zed "$HOME/.config/zed" [
    "themes/matugen.json"
  ];
}
