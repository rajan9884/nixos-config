# nixos-config — reproducible Hyprland desktop

> New machine from the minimal ISO? Follow **[INSTALL.md](INSTALL.md)**
> (partition → minimal install → `setup.sh`). Below is the reference.

```
~/nixos-config/          # this repo (you are here)
  setup.sh               # fresh-install automation (clone, hw config, swap guard, rebuild)
  flake.nix              # inputs: nixpkgs-unstable, home-manager (wallpapers NOT an input — flatten-copied)
  flake.lock             # pinned — commit after every `nix flake update`
  hosts/laptop/
    configuration.nix    # system: boot (linuxPackages_latest), Wayland env, pipewire, docker, user, gc
    hardware-configuration.nix  # GENERATED for THIS machine — setup.sh regenerates it, do not copy blindly
  home/rajan.nix         # home-manager: services, shell, dconf, mime
  modules/
    system/desktop.nix   # hyprland+uwsm, portals, greetd, polkit, uinput
    home/
      packages.nix       # user packages BY TOPIC (edit here, `nrs`)
      bin.nix + bin/     # ~/.local/bin helpers (store symlinks, immutable) incl. wallpapers-sync
      hypr.nix + hypr/   # + theme-chain.sh (mutable sync via lib/sync-dir.nix)
      waybar.nix + waybar/ | rofi | kitty | btop | gtk | matugen | nvim | swaync | zed
      rofimoji.nix       # read-only xdg.dataFile (never mutated)
      wallpapers.nix     # flatten-copies ~/wallpapers -> ~/.local/share/wallpapers (0 store bytes, no subdirs)
  lib/sync-dir.nix       # ONE rsync helper (all app modules use it)
  assets/fallback-wallpaper.jpg  # offline first-boot fallback (single image, flat store)
~/wallpapers/            # sibling repo (https://github.com/rajan9884/wallpapers.git): flat Wallpaper/ collection
~/.local/share/wallpapers/  # GENERATED flat store: *.jpg/*.png directly inside, NO subdirs (never edit by hand)
/etc/nixos -> ~/nixos-config  # symlink for compat (`nrs` uses the absolute repo path)
```

Wallpapers are **flat by contract**: every picker, `swww-all.sh`, matugen
seed and theme script reads `~/.local/share/wallpapers/*` at depth 1.
`modules/home/wallpapers.nix` copies every image found anywhere under
`~/wallpapers` (`.git` excluded) into that dir on each rebuild, so upstream
nesting never matters. Name collisions get a `_parentdir` suffix — nothing
is silently overwritten. After `git pull` in `~/wallpapers`, run
`wallpapers-sync` (same logic, also in `~/.local/bin`).

## Fresh install (automated)

On a minimal NixOS install (any ISO kernel — the flake boots
`linuxPackages_latest` after the first switch):

```bash
git clone https://github.com/rajan9884/nixos-config.git ~/nixos-config
~/nixos-config/setup.sh
```

`setup.sh` is idempotent (safe to re-run) and does: clone/update both
repos → `wallpapers-sync` now (flat store exists pre-rebuild) →
regenerate `hosts/laptop/hardware-configuration.nix` for **this** machine →
rewrite the hardcoded `rajan` user if yours differs (`--user NAME`) →
symlink `/etc/nixos` → rebuild. Flags: `--keep-hardware`, `--no-rebuild`,
`--no-swap`, `--attr NAME`, `--user NAME`.

One-liner (no pre-clone):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rajan9884/nixos-config/main/setup.sh)
```

Then once, after first login via tuigreet:

```bash
ACTIVE_THEME=Noro ~/.config/hypr/theme-chain.sh
```

## Fresh install (manual)

```bash
git clone https://github.com/rajan9884/nixos-config.git ~/nixos-config
git clone https://github.com/rajan9884/wallpapers.git ~/wallpapers
bash ~/nixos-config/modules/home/bin/wallpapers-sync   # flat copy now, so first boot has wallpapers
sudo rm -rf /etc/nixos
sudo ln -s "$HOME/nixos-config" /etc/nixos
sudo nixos-generate-config --show-hardware-config > ~/nixos-config/hosts/laptop/hardware-configuration.nix
# First switch (HM backs up colliding ~/.config files to *.hm-backup):
sudo nixos-rebuild switch --flake ~/nixos-config#laptop
# Once: init theme chain + wallpaper (then reboot, log in via tuigreet):
ACTIVE_THEME=Noro ~/.config/hypr/theme-chain.sh
```

> Username: the flake hardcodes user `rajan`. If your user differs,
> `setup.sh --user <name>` rewrites it in `flake.nix`, `home/rajan.nix`
> and `hosts/laptop/configuration.nix` automatically.

## Daily

```bash
nrs   # switch
nrb   # build without switching
nrc   # git add -A + nix flake check (run before commit)
wallpapers-sync   # re-sync ~/wallpapers -> flat store after git pull
nh os switch ~/nixos-config          # prettier alternative
gh auth login && gh auth setup-git   # token -> ~/.config/gh/hosts.yml (credential.helper=store)
```

## Troubleshooting

* **Out of memory during build (6GB RAM):** not a bad command, not a
  broken nix. `nixos-unstable` occasionally misses the binary cache and
  compiles locally, and Nix runs one job per core by default — each
  Rust/C++ link can eat GBs. `setup.sh` handles this automatically
  (8GB `/swapfile` if swap <4GB, `--max-jobs 2 --cores 2` under 8GB RAM,
  `--max-jobs 1` at ≤4GB). Manual equivalent:
  ```bash
  sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile \
    && sudo mkswap /swapfile && sudo swapon /swapfile
  sudo nixos-rebuild switch --flake ~/nixos-config#laptop --max-jobs 2 --cores 2
  ```
  Diagnose with `dmesg | grep -i "out of memory"`, `free -h`, `df -h / /nix`.
  Also: install from the committed `flake.lock` — don't `nix flake update`
  right before a low-RAM install (fresh unstable commits may lack cache).
* **No wallpaper / unstyled waybar after first boot:** run
  `wallpapers-sync`, then `~/.config/hypr/scripts/swww-all.sh
  ~/.local/share/wallpapers/<pick-one>`.
* **`~/.config/<app>` drifted:** delete it and rebuild — mutable sync
  restores the repo baseline (matugen outputs regenerate on next
  wallpaper switch).

## Conventions

* System closure stays minimal (`environment.systemPackages`: git/nvim/boot + nh).
  Desktop apps go in `modules/home/packages.nix`.
* Kernel is `linuxPackages_latest` (latest, not LTS) — no out-of-tree
  modules in this config, so kernel bumps are safe.
* Mutable sync (`lib/sync-dir.nix`): rsync WITHOUT `--delete` — vendored files
  update, matugen-generated files survive. If `~/.config/<app>` drifts,
  delete it and rebuild to resync from repo.
* `wallpapers` never live here — they live in `~/wallpapers`
  (flat-synced; `~/wallpapers/install.sh --flat` same contract on other distros).
* `system.stateVersion` / `home.stateVersion` stay at install version (25.11).
  Do not bump on reinstall.
* GC: `--delete-older-than 30d` + `configurationLimit 10` + docker `autoPrune`
  weekly. `system.autoUpgrade` pulls nixpkgs weekly (system only).
