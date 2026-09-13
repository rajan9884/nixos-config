# System-level config — Pure Wayland + Intel Iris Xe (i5-13500H)
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/desktop.nix
    ../../modules/system/power.nix
  ];

  # ── Boot ──────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "i915" ];
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # ── Host / locale ─────────────────────────────
  networking.hostName = "laptop";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Intel graphics (Iris Xe, i5-13500H) ───────
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Hardware accelerated video decoding (VA-API)
    ];
  };

  # ── Pure Wayland session environment ──────────
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    # Force Chromium, Electron, and Ozone apps to use Wayland natively without X11
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland;xcb";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # ── Audio / Bluetooth ─────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # ── Power & swap management ───────────────────
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  zramSwap.enable = true;
  services.fwupd.enable = true;

  # ── Containers (lazydocker keybind SUPER SHIFT+D expects this) ──
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Unattended flake updates (system part). Home part stays manual via `nrs`
  # so a broken Hyprland theme never auto-applies before you can check it.
  system.autoUpgrade = {
    enable = true;
    flake = "/home/rajan/nixos-config#laptop";
    flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
    dates = "weekly";
    randomizedDelaySec = "45min";
  };

  # ── Other OS mounts (dual-boot file access) ──
  # Friendly paths in Nautilus: /mnt/windows, /mnt/omarchy.
  # `nofail` so a hibernated Windows (Fast Startup) or a changed
  # partition can never block boot — the mount is just skipped.
  # NOTE: turn off Windows Fast Startup (or use Restart, not Shut down,
  # when coming here) or the NTFS volume arrives hibernated and the
  # mount is skipped / read-only.
  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/84045EA2045E9750";
    fsType = "ntfs3";
    options = [ "rw" "uid=1000" "gid=100" "noatime" "nofail" ];
  };
  fileSystems."/mnt/omarchy" = {
    device = "/dev/disk/by-uuid/2b2e3c31-3522-41b6-889d-5415f66483d9";
    fsType = "btrfs";
    options = [ "rw" "noatime" "nofail" ];
  };

  # ── User ──────────────────────────────────────
  users.users.rajan = {
    isNormalUser = true;
    description = "rajan";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "docker" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # dconf dbus service: required for home-manager `dconf.settings`
  # (portal GTK settings such as the icon theme) to take effect.
  programs.dconf.enable = true;

  # Run unpatched dynamic binaries (VS Code language servers / npm tools,
  # mise/node toolchains, opencode plugins).
  # Each entry needed by: stdenv.cc.cc+zlib+glibc (node/bun/mise ELFs),
  # openssl+curl (gh, lazygit, language servers), util-linux (uuid libs).
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    glibc
    openssl
    curl
    util-linux
  ];

  # Preserve the previously-enabled Cloudflare WARP service from the minimal
  # /etc/nixos install so switching to this flake is not a regression.
  services.cloudflare-warp.enable = true;

  # ── Unfree + fonts ────────────────────────────
  nixpkgs.config.allowUnfree = true;
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # ── System packages ───────────────────────────
  # Minimal on purpose: boot/recovery + git. Desktop apps live in
  # modules/home/packages.nix (user profile, not system closure).
  environment.systemPackages = with pkgs; [
    git
    neovim
    wget
    curl
    efibootmgr
    nh # `nh os switch ~/nixos-config` — better output + auto `nix flake check`
    nix-output-monitor
  ];

  # ── Flakes & Nix settings ─────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    # 30d (not 7d): with 10+ rebuilds/day, 7d GCs a generation you may
    # still want to roll back to tomorrow. configurationLimit caps /boot.
    options = "--delete-older-than 30d";
    persistent = true;
  };

  # Kept at install version on purpose — do NOT bump on every reinstall.
  # See: https://nixos.org/manual/release-notes.html#sec-upgrading
  system.stateVersion = "25.11";
}
