# Home Manager — port of install.sh §§1-5 + pkglist + shell/.
# Strategy (deliberate, minimal-divergence first port):
#   - App configs are NOT rewritten in Nix. They are symlinked verbatim from
#     your existing ~/dotfiles via mkOutOfStoreSymlink — exactly what
#     install.sh `link_config` did. Edit in ~/dotfiles, reload, same workflow.
#   - Packages from pkglist/native.txt + foreign.txt are mapped to nixpkgs
#     below. AUR-only apps that don't exist in nixpkgs are noted at the bottom.
#   - Shell (zsh/bash) IS natively managed here because Arch hardcoded
#     /usr/share/fzf paths that don't exist on NixOS. Prompt/plugins ported.
{ config, pkgs, lib, ... }:

let
  dotfiles = "/home/rajan/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.username = "rajan";
  home.homeDirectory = "/home/rajan";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  # ── App configs, verbatim (was: install.sh link_config) ──
  # Each entry reproduces one `ln -s ~/dotfiles/config/<app> ~/.config/<app>`.
  xdg.configFile = {
    "hypr".source = outOfStore "${dotfiles}/config/hypr";
    "waybar".source = outOfStore "${dotfiles}/config/waybar";
    "rofi".source = outOfStore "${dotfiles}/config/rofi";
    "kitty".source = outOfStore "${dotfiles}/config/kitty";
    "btop".source = outOfStore "${dotfiles}/config/btop";
    "swayosd".source = outOfStore "${dotfiles}/config/swayosd";
    "matugen".source = outOfStore "${dotfiles}/config/matugen";
    "nvim".source = outOfStore "${dotfiles}/config/nvim";
    "swaync".source = outOfStore "${dotfiles}/config/swaync";
    "gtk-3.0".source = outOfStore "${dotfiles}/config/gtk-3.0";
    "gtk-4.0".source = outOfStore "${dotfiles}/config/gtk-4.0";
    # Generated-only dirs (install.sh GENERATED_APPS): matugen templates write here.
    "fastfetch".source = outOfStore "${dotfiles}/config/fastfetch";
    "helium-theme".source = outOfStore "${dotfiles}/config/helium-theme";
  };

  # Active-theme symlink chain (was: install.sh §3, default Noro).
  # Run modules/theme-chain.sh once after first switch to initialize.

  # ── Wallpapers (was: install.sh §4 → ~/.local/share/wallpapers) ──
  xdg.dataFile."wallpapers".source = outOfStore "${dotfiles}/wallpapers";

  # Rofimoji themes (was: install.sh §5d → ~/.local/share/rofimoji/themes)
  xdg.dataFile."rofimoji/themes".source = outOfStore "${dotfiles}/rofimoji/themes";

  # ── Helper scripts (from ~/dotfiles/bin/ → ~/.local/bin) ──
  home.file = {
    ".local/bin/arch-menu-images".source = outOfStore "${dotfiles}/bin/arch-menu-images";
    ".local/bin/arch-theme-apply".source = outOfStore "${dotfiles}/bin/arch-theme-apply";
    ".local/bin/arch-theme-switcher".source = outOfStore "${dotfiles}/bin/arch-theme-switcher";
    ".local/bin/arch-wallpaper-picker".source = outOfStore "${dotfiles}/bin/arch-wallpaper-picker";
    ".local/bin/capture-region".source = outOfStore "${dotfiles}/bin/capture-region";
    ".local/bin/capture-satty".source = outOfStore "${dotfiles}/bin/capture-satty";
    ".local/bin/capture-screen".source = outOfStore "${dotfiles}/bin/capture-screen";
    ".local/bin/menu-calc".source = outOfStore "${dotfiles}/bin/menu-calc";
    ".local/bin/menu-clipboard".source = outOfStore "${dotfiles}/bin/menu-clipboard";
    ".local/bin/menu-emoji".source = outOfStore "${dotfiles}/bin/menu-emoji";
    ".local/bin/menu-herdr-keybindings".source = outOfStore "${dotfiles}/bin/menu-herdr-keybindings";
    ".local/bin/menu-share".source = outOfStore "${dotfiles}/bin/menu-share";
    ".local/bin/menu-share-prompt".source = outOfStore "${dotfiles}/bin/menu-share-prompt";
    ".local/bin/menu-tmux-keybindings".source = outOfStore "${dotfiles}/bin/menu-tmux-keybindings";
    ".local/bin/menu-transcode".source = outOfStore "${dotfiles}/bin/menu-transcode";
    ".local/bin/menu-transcode-prompt".source = outOfStore "${dotfiles}/bin/menu-transcode-prompt";
    ".local/bin/night-light-toggle".source = outOfStore "${dotfiles}/bin/night-light-toggle";
    ".local/bin/ocr-extract".source = outOfStore "${dotfiles}/bin/ocr-extract";
    ".local/bin/power-profiles".source = outOfStore "${dotfiles}/bin/power-profiles";
    ".local/bin/wall-selector".source = outOfStore "${dotfiles}/bin/wall-selector";
    ".local/bin/waybar-selector".source = outOfStore "${dotfiles}/bin/waybar-selector";
    ".local/bin/wifi-share".source = outOfStore "${dotfiles}/bin/wifi-share";
    ".local/bin/wifi-share-prompt".source = outOfStore "${dotfiles}/bin/wifi-share-prompt";
    ".local/bin/window-close-all".source = outOfStore "${dotfiles}/bin/window-close-all";
  };
  home.sessionPath = [ "$HOME/.local/bin" "$HOME/.opencode/bin" "$HOME/.kilo/bin" ];

  # ── Packages (Minimal Port: Kitty, Chromium, Bibata, Wayland Desktop) ──
  home.packages = with pkgs; [
    # Compositor session & utilities (hyprland is enabled in system config)
    hypridle
    hyprlock
    hyprpicker
    hyprsunset

    # Bar / launcher / notifications / OSD
    waybar
    rofi
    rofi-calc
    rofimoji
    swaynotificationcenter
    swayosd

    # Wallpaper + theming pipeline
    awww
    matugen
    bibata-cursors
    papirus-icon-theme
    papirus-folders
    adw-gtk3
    nwg-look
    libsForQt5.qt5ct
    qt6Packages.qt6ct

    # Terminal / editor / multiplexer
    kitty
    neovim
    tmux

    # Terminal file manager & viewers
    yazi
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
    github-cli
    jq
    bc
    socat
    inotify-tools
    rsync
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
    brightnessctl
    playerctl

    # System monitor & network applet
    networkmanagerapplet
    iw
    nvtopPackages.intel

    # Browser (pure Wayland via NIXOS_OZONE_WL)
    chromium

    # Wayland / desktop integration
    libappindicator-gtk3
    gsettings-desktop-schemas
    webp-pixbuf-loader
  ];

  # ── AUR packages with NO nixpkgs equivalent (manual step) ──
  # - helium-browser-bin: no nixpkgs package. Option A: Flatpak/WebApp
  #   (`webapp-install` helper already exists). Option B: fetch the upstream
  #   binary tarball with a custom derivation — say the word and I'll write it.
  #   vars.lua currently defaults to chromium, so nothing breaks meanwhile.
  # - voxtype-bin (dictation, F9): not packaged. Install via cargo or keep an
  #   Arch toolbox/distrobox for it. Binds degrade gracefully if missing.
  # - chatgpt-desktop, claude-desktop, cliamp-bin, cloudflare-warp-bin:
  #   cloudflare-warp IS in nixpkgs as `cloudflare-warp` — add it above if you
  #   use WARP. The *-desktop Electron wrappers: use webapp-install or Flatpak.
  # - ttf-joypixels, ttf-material-design-icons-extended, ttf-rubik-vf,
  #   ttf-symbola, otf-aurulent-nerd: nixpkgs has joypixels? No (license).
  #   Use nerd-fonts.* +     noto-fonts-color-emoji; add material-design-icons via
  #   `material-design-icons` font package if glyphs are missing in waybar.

  # ── Shell: zsh (ported from shell/zshrc) ──
  # Why native instead of symlink: Arch zshrc sourced /usr/share/fzf/* which
  # doesn't exist on NixOS. programs.* wires fzf/zoxide/atuin/direnv/starship
  # via their Nix integrations instead.
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      ff = "fzf";
    };
    # Matches your custom prompt + LS_COLORS + y() + PATH from shell/zshrc.
    # NOTE: on home-manager older than ~25.05 this option was `initExtra`.
    initContent = ''
      export LS_COLORS="di=38;5;45:ln=38;5;75:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32"
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      PROMPT=$'\n%{%F{magenta}%}%{%K{magenta}%}%{%F{black}%}  %{%F{white}%} %~ %{%k%}%{%F{magenta}%}%{%f%}\n%{%F{magenta}%}❯ %{%f%}'
      RPROMPT=""
      export EDITOR="nvim" VISUAL="nvim"
      export FZF_DEFAULT_OPTS="--height 40% --reverse --border"
      export PATH="$HOME/.opencode/bin:$HOME/.kilo/bin:$HOME/.local/bin:$PATH"
      fastfetch
      y() {
        local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
        command yazi "$@" --cwd-file="$tmp"
        local cwd="$(cat -- "$tmp" 2>/dev/null)"
        rm -f -- "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
      }
    '';
  };
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      ff = "fzf";
    };
    initExtra = ''
      # NOTE: home-manager ≥25.11 renamed this option to `initContent`.
      # If you get "unknown option" on a newer home-manager, rename it.
      export FZF_DEFAULT_OPTS="--height 40% --reverse --border"
      export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
      y() {
        local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
        command yazi "$@" --cwd-file="$tmp"
        local cwd="$(cat -- "$tmp" 2>/dev/null)"
        rm -f -- "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
      }
      eval "$(starship init bash)"
    '';
  };

  programs.fzf = {
    enable = true; # replaces /usr/share/fzf sourcing
    # Atuin owns Ctrl-R (as on Arch); fzf keeps Ctrl-T + Alt-C.
    historyWidget.command = "";
  };
  programs.zoxide = {
    enable = true;
    options = [ "--cmd z" ];
  };
  programs.atuin = {
    enable = true;
    settings = { enter_accept = false; };
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.starship.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "rj9884";
        email = "rj.vidyagyan@gmail.com";
      };
      init.defaultBranch = "main";
      color.ui = "auto";
      core.editor = "nvim";
      pull.rebase = false;
    };
  };

  # ── Default apps (was: install.sh §7 imv MIME sed) ──
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
    };
  };

  # Matugen writes generated files (waybar/colors.css, hypr/colors.lua, …)
  # into ~/.config at runtime — same as Arch, no Nix change needed. Just run
  # once after first login:
  #   matugen image ~/.local/share/wallpapers/noro/<pick-one> \
  #     -c ~/.config/matugen/config.toml --source-color-index 0
}
