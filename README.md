# nixos-config — reproducible Hyprland desktop

```
~/nixos-config/          # this repo (you are here)
  flake.nix              # inputs: nixpkgs-unstable, home-manager, wallpapers=path:../wallpapers
  flake.lock             # pinned — commit after every `nix flake update`
  hosts/laptop/
    configuration.nix    # system: boot, Wayland env, pipewire, docker, user, gc
    hardware-configuration.nix  # GENERATED — do not hand-edit
  home/rajan.nix         # home-manager: services, shell, dconf, mime
  modules/
    system/desktop.nix   # hyprland+uwsm, portals, greetd, polkit, uinput
    home/
      packages.nix       # user packages BY TOPIC (edit here, `nrs`)
      bin.nix + bin/     # ~/.local/bin helpers (store symlinks, immutable)
      hypr.nix + hypr/   # + theme-chain.sh (mutable sync via lib/sync-dir.nix)
      waybar.nix + waybar/ | rofi | kitty | btop | gtk | matugen | nvim | swaync | zed
      rofimoji.nix       # read-only xdg.dataFile (never mutated)
      wallpapers.nix     # xdg.dataFile from flake input `wallpapers`
  lib/sync-dir.nix       # ONE rsync helper (all app modules use it)
  assets/fallback-wallpaper.jpg  # offline first-boot fallback (noro default)
~/wallpapers/            # sibling repo (cross-distro): glass/material/modern/noro/retro/optimized
/etc/nixos -> /home/rajan/nixos-config  # symlink for compat (`nrs` uses absolute path)
```

## Fresh install (reproducible)

```bash
# 1. Partition + minimal NixOS install, then:
sudo nixos-generate-config --show-hardware-config > /tmp/hw.nix  # compare
git clone <remote>/nixos-config.git ~/nixos-config
git clone <remote>/wallpapers.git ~/wallpapers
sudo rm -rf /etc/nixos
sudo ln -s /home/rajan/nixos-config /etc/nixos
cp /tmp/hw.nix ~/nixos-config/hosts/laptop/hardware-configuration.nix
# 2. First switch (HM backs up colliding ~/.config files to *.hm-backup):
sudo nixos-rebuild switch --flake ~/nixos-config#laptop
# 3. Once: init theme chain + wallpaper (then reboot, log in via tuigreet):
ACTIVE_THEME=Noro ~/.config/hypr/theme-chain.sh
```

## Daily

```bash
nrs   # switch
nrb   # build without switching
nrc   # git add -A + nix flake check (run before commit)
nh os switch ~/nixos-config          # prettier alternative
gh auth login && gh auth setup-git   # token -> ~/.config/gh/hosts.yml (credential.helper=store)
```

## Conventions

* System closure stays minimal (`environment.systemPackages`: git/nvim/boot + nh).
  Desktop apps go in `modules/home/packages.nix`.
* Mutable sync (`lib/sync-dir.nix`): rsync WITHOUT `--delete` — vendored files
  update, matugen-generated files survive. If `~/.config/<app>` drifts,
  delete it and rebuild to resync from repo.
* `wallpapers` never live here — they live in `~/wallpapers`
  (`install.sh --link` works on Arch/Fedora/Ubuntu too).
* `system.stateVersion` / `home.stateVersion` stay at install version (25.11).
  Do not bump on reinstall.
* GC: `--delete-older-than 30d` + `configurationLimit 10` + docker `autoPrune`
  weekly. `system.autoUpgrade` pulls nixpkgs weekly (system only).
