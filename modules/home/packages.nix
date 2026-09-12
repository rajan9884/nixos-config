# modules/home/packages.nix — user packages by topic.
# Single place to add/remove apps: edit a group below, `nrs`.
# Rules: no `nix-env -i`, no `npm i -g`, no manual ELFs in ~/.local/bin.
# One-off try: `try nixpkgs#foo`. Project dev: `nix develop` + flake.nix.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Compositor session & utilities (hyprland enabled in system config)
    hypridle
    hyprlock
    hyprpicker
    hyprsunset

    # Bar / launcher / notifications / OSD
    waybar
    rofi
    rofimoji
    swaynotificationcenter
    swayosd

    # Wallpaper + theming pipeline
    awww
    matugen
    bibata-cursors
    papirus-icon-theme
    # Fallback icon theme: xdg-desktop-portal reports icon-theme from dconf
    # (default 'Adwaita'). If Adwaita is missing every lookup fails and
    # swayosd shows a "missing image" placeholder for volume/brightness.
    adwaita-icon-theme
    dconf
    papirus-folders
    adw-gtk3
    nwg-look
    libsForQt5.qt5ct
    qt6Packages.qt6ct

    # Terminal / editor / multiplexer
    kitty
    neovim
    gcc # nvim-treesitter parsers need a C compiler
    gnumake
    tmux
    herdr

    # Terminal file manager & viewers
    yazi
    nautilus
    imv
    mpv
    ffmpegthumbnailer
    chafa

    # Core CLI & shell utilities
    eza
    bat
    fd
    ripgrep
    tree
    btop
    fastfetch
    cava
    lazygit
    lazydocker
    github-cli
    gum # webapp-install hard-requires it
    jq
    bc
    socat
    inotify-tools
    rsync
    python3 # swww-all.sh step 7.5 (vscode-theme-apply.py)
    unzip
    wget
    file # `file -b --mime-type` (webapp-install icon download)

    # Wayland screenshots / clipboard / OCR
    grim
    slurp
    satty
    wf-recorder
    wl-clipboard
    wl-clip-persist
    cliphist
    wtype
    tesseract
    imagemagick

    # Audio / brightness keys
    pamixer
    pulsemixer
    wiremix
    wireplumber # wpctl (sink cycling)
    pulseaudio # pactl (used by hypr/scripts/osd-volume.sh)
    brightnessctl
    playerctl
    psmisc # killall (swww-all.sh)
    procps # pkill (swww-all.sh)
    libnotify # notify-send

    # System monitor & network applet
    networkmanagerapplet
    iw
    nvtopPackages.intel

    # Browser (pure Wayland via NIXOS_OZONE_WL)
    # --load-extension auto-loads the matugen-generated unpacked theme
    # (~/.config/helium-theme/manifest.json) on every launch, including
    # --app windows from webapp-launch.
    (chromium.override {
      commandLineArgs = [
        "--load-extension=/home/rajan/.config/helium-theme"
        "--disable-features=ExtensionDeveloperModeWarning"
      ];
    })

    # Wayland / desktop integration
    libappindicator-gtk3
    gsettings-desktop-schemas
    webp-pixbuf-loader

    # AI CLIs: available in EVERY shell + GUI session via nix profile
    opencode
    kilo
    nodejs
    bun
    mise

    # Nix tooling (config maintenance)
    nh # `nh os switch` / `nh home switch` / `nh clean`
    nil # Nix LSP (Zed/nvim)
    nixd # Nix LSP (alt)
  ];
}
