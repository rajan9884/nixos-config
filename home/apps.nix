# Single place to add/remove user apps.
# Edit this file, `git add` it, then `sudo nixos-rebuild switch --flake .#laptop`.
# Good practice: everything declarative here via nixpkgs.
# Bad practices to avoid:
#   - `nix-env -i`, `sudo nix-channel`, `nix-shell -p <pkg>` (imperative, not reproducible)
#   - `npm i -g`, `pip install --user`, manual tarballs in ~/.local/bin
#   - system-wide `environment.systemPackages` for desktop apps (keep that minimal: git/vim/boot tools only)
# Use per-project shells instead: `nix shell nixpkgs#foo` for one-off try, `nix develop` + flake.nix for dev.
{ pkgs }:

with pkgs; [
  # Compositor session & utilities (hyprland is enabled in system config)
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
  # Fallback icon theme: the xdg-desktop-portal Settings backend reports
  # icon-theme from dconf (default 'Adwaita'). If Adwaita isn't installed,
  # EVERY icon lookup fails and swayosd shows the same "missing image"
  # placeholder for volume and brightness OSDs. dconf below sets Papirus,
  # this package guarantees the Adwaita fallback resolves regardless.
  adwaita-icon-theme
  dconf # for `dconf.settings` activation (writes ~/.config/dconf/user)
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

  # Terminal file manager & viewers
  yazi
  nautilus # Files (nautilus-cwd / nautilus-gnome helpers)
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
  gum # gum input/choose prompts (webapp-install hard-requires it)
  jq
  bc
  socat
  inotify-tools
  rsync
  python3 # swww-all.sh step 7.5 (vscode-theme-apply.py)
  unzip
  wget

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
  pulseaudio # pactl (used by ~/.config/hypr/scripts/osd-volume.sh)
  brightnessctl
  playerctl
  psmisc # killall (swww-all.sh)
  procps # pkill (swww-all.sh)
  libnotify # notify-send (vol/touchpad feedback)

  # System monitor & network applet
  networkmanagerapplet
  iw
  nvtopPackages.intel

  # Browser (pure Wayland via NIXOS_OZONE_WL)
  # --load-extension auto-loads the matugen-generated unpacked theme
  # (~/.config/helium-theme/manifest.json) on every launch, including
  # --app windows from webapp-launch. swww-all.sh bumps its version per
  # wallpaper so a browser restart picks up new colors (it notifies you).
  # The dev-mode nag for unpacked extensions is suppressed.
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

  # ── AI CLIs: available in EVERY shell + GUI session via nix profile ──
  # Single rule for all future code/CLIs: add the nixpkgs name here, rebuild.
  # No manual ELFs, no ~/.kilo/bin, no ~/.opencode/bin, no `npm i -g`.
  opencode
  kilo
  nodejs
  bun
  mise
]
