# INSTALL — minimal ISO → this desktop

You do partitioning/formatting/mounting yourself. Everything after that is
here. Tested path: official minimal NixOS ISO (64-bit Intel/AMD, 26.05).

Starting state assumed below: partitions formatted, root mounted at `/mnt`,
EFI partition mounted at `/mnt/boot`. Verify before continuing:

```bash
lsblk -f
mount | grep /mnt   # must show /mnt and /mnt/boot
```

> Username: this flake hardcodes user **`rajan`**. Easiest is to create the
> user `rajan` in step 2. Any other name works too — `setup.sh` rewrites it
> automatically (`setup.sh --user <name>`).

## A. Minimal install (ISO live environment)

**1. Generate the stock config:**

```bash
sudo nixos-generate-config --root /mnt
```

**2. Edit `/mnt/etc/nixos/configuration.nix`** — minimal viable content
(keep the generated `hardware-configuration.nix` import, replace the rest):

```nix
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Kolkata";

  users.users.rajan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";   # change it right after first login (passwd)
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [ git neovim wget curl ];
  system.stateVersion = "26.05";   # match the ISO you installed from
}
```

**3. Install and reboot:**

```bash
sudo nixos-install
# when prompted, set a root password (or leave empty if offered)
sudo reboot   # remove the ISO when the machine restarts
```

**4. Log in on the TTY as `rajan`** (no desktop yet — expected),
change your password, check network:

```bash
passwd
ping -c 3 nixos.org
```

## B. Deploy this config (on the installed system)

**5. Clone both repos:**

```bash
git clone https://github.com/rajan9884/nixos-config.git ~/nixos-config
git clone https://github.com/rajan9884/wallpapers.git ~/wallpapers
```

**6. Run the setup script** (idempotent — safe to re-run):

```bash
~/nixos-config/setup.sh
```

It does, in order: pull latest repos → flatten-copy wallpapers into
`~/.local/share/wallpapers` (so first boot has backgrounds) → regenerate
`hosts/laptop/hardware-configuration.nix` for **this** machine → rewrite
user `rajan` if yours differs → symlink `/etc/nixos` → `nixos-rebuild
switch`. Low-RAM machines (<8GB): it creates an 8GB `/swapfile` and caps
build parallelism automatically — just let it run, it takes a while.

Useful flags: `--user NAME` (non-`rajan` user), `--keep-hardware`,
`--no-rebuild` (clone+link only), `--no-swap`.

**7. Reboot, log in via tuigreet, init the theme once:**

```bash
sudo reboot
# pick Hyprland in tuigreet, log in, open a terminal ($MOD+Return):
pick a wallpaper:  <Super>+Ctrl+Space  (or Super+R for random)
```

You should now have wallpaper + themed bar. Reboot once more if anything
looks unstyled (first-login `wallpaper-init` service runs matugen).

## C. Post-install checklist

```bash
passwd                                  # if still on the temp password
gh auth login && gh auth setup-git      # git auth
wallpapers-sync                         # after any git pull in ~/wallpapers
nrs                                     # rebuild+switch after config edits
```

- Change wallpaper: `Super+W` (or `wallpapers-sync` keeps the flat store fresh).
- Single-boot machine: the `/mnt/windows` + `/mnt/omarchy` entries in
  `hosts/laptop/configuration.nix` are `nofail` (skipped silently), delete
  them if they'll never exist.
- Stuck? See `README.md` → Troubleshooting (OOM, missing wallpaper/bar).

## Manual alternative (no setup.sh)

```bash
git clone https://github.com/rajan9884/nixos-config.git ~/nixos-config
git clone https://github.com/rajan9884/wallpapers.git ~/wallpapers
bash ~/nixos-config/modules/home/bin/wallpapers-sync
sudo rm -rf /etc/nixos
sudo ln -s "$HOME/nixos-config" /etc/nixos
sudo nixos-generate-config --show-hardware-config > ~/nixos-config/hosts/laptop/hardware-configuration.nix
# low RAM? add swap first, then append: --max-jobs 2 --cores 2
sudo nixos-rebuild switch --flake ~/nixos-config#laptop
pick a wallpaper:  <Super>+Ctrl+Space  (or Super+R for random)
```
