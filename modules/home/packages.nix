# modules/home/packages.nix — user packages by topic.
# Single place to add/remove apps: edit a group below, `nrs`.
# Rules: no `nix-env -i`, no `npm i -g`, no manual ELFs in ~/.local/bin.
# One-off try: `try nixpkgs#foo`. Project dev: `nix develop` + flake.nix.
{ pkgs, ... }:
let
  # gdk-pixbuf only decodes formats listed in a loaders.cache file.
  # Installing webp-pixbuf-loader alone never registers it, which left every
  # .webp (the whole optimized/ collection) thumbnail-less in rofi menus.
  # This cache = stock loaders (png/jpg/gif/…) + svg + webp, deployed to a
  # stable path and baked into our rofi wrapper below.
  pixbufLoaders = pkgs.runCommand "gdk-pixbuf-loaders.cache" { } ''
    ${pkgs.gdk-pixbuf.dev}/bin/gdk-pixbuf-query-loaders > $out
    ${pkgs.gdk-pixbuf.dev}/bin/gdk-pixbuf-query-loaders \
      ${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader_svg.so >> $out
    ${pkgs.gdk-pixbuf.dev}/bin/gdk-pixbuf-query-loaders \
      ${pkgs.webp-pixbuf-loader}/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-webp.so >> $out
  '';

  # nixpkgs wraps rofi in a binary wrapper that --set's GDK_PIXBUF_MODULE_FILE
  # to librsvg's cache (no webp), clobbering any env export — which is why the
  # menu-script export alone couldn't fix webp thumbnails. Re-wrap the
  # unwrapped binary with identical gapps args but our webp-inclusive cache.
  rofiWebp = pkgs.symlinkJoin {
    name = "rofi-webp";
    paths = [ pkgs.rofi ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      rm "$out/bin/rofi"
      makeBinaryWrapper ${pkgs.rofi-unwrapped}/bin/rofi "$out/bin/rofi" \
        --prefix GIO_EXTRA_MODULES : "${pkgs.dconf.lib}/lib/gio/modules" \
        --set GDK_PIXBUF_MODULE_FILE "${pixbufLoaders}" \
        --set-default XDG_DATA_DIRS "/usr/local/share/:/usr/share/" \
        --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
        --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}" \
        --prefix XDG_DATA_DIRS : "${pkgs.rofi}/share" \
        --prefix XDG_DATA_DIRS : "${pkgs.hicolor-icon-theme}/share"
    '';
  };
in
{
  home.file.".cache/gdk-pixbuf/loaders.cache".source = pixbufLoaders;

  home.packages = with pkgs; [
    # Compositor session & utilities (hyprland enabled in system config)
    hypridle
    hyprlock
    hyprpicker
    hyprsunset

    # Bar / launcher / notifications / OSD
    waybar
    rofiWebp
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
    
    # Text editor
    gnome-text-editor
  ];
}
