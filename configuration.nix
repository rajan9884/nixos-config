# System-level config — Pure Wayland + Intel Iris Xe (i5-13500H)
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/desktop.nix
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
  virtualisation.docker.enable = true;

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

  # Run unpatched dynamic binaries (VS Code / language servers / npm tools,
  # manual ~/.kilo/bin/kilo ELF, mise/node toolchains, opencode plugins).
  # Libraries mirror the previously-working /etc/nixos setup so kilo keeps
  # running after switching to this flake.
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
  environment.systemPackages = with pkgs; [
    git
    neovim
    wget
    curl
    efibootmgr
  ];

  # ── Flakes & Nix settings ─────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
    persistent = true;
  };

  system.stateVersion = "25.11";
}
