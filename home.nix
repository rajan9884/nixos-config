# Home Manager — declarative desktop (packages + services + app modules).
# Strategy: everything needed to restore this machine lives in this repo.
#   - App configs live in ./modules/<app>/ (a <app>.nix module + <app>/ dir)
#     and are synced into place at activation. No ~/dotfiles checkout,
#     no out-of-store symlinks, no pacman-era installer needed on NixOS.
#   - Packages are mapped to nixpkgs below.
#   - Shell (zsh/bash) is natively managed here. Prompt/plugins ported.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/bin.nix
    ./modules/btop.nix
    ./modules/gtk.nix
    ./modules/hypr.nix
    ./modules/kitty.nix
    ./modules/matugen.nix
    ./modules/nvim.nix
    ./modules/rofimoji.nix
    ./modules/rofi.nix
    ./modules/swaync.nix
    ./modules/wallpapers.nix
    ./modules/waybar.nix
    ./modules/zed.nix
  ];

  home.username = "rajan";
  home.homeDirectory = "/home/rajan";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  # Active-theme symlink chain (was: install.sh §3, default Noro).
  # Run modules/theme-chain.sh once after first switch to initialize.

  # ~/.local/bin only. GUI + shells get it via HM sessionPath.
  # (Removed leftovers: mise shims, ~/.opencode/bin, ~/.kilo/bin — all
  # tools now come from nixpkgs via home.nix, no manual ELFs.)
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # ── Packages ──
  # Single place to add/remove user apps: edit the list below, rebuild.
  # Good practice: everything declarative here via nixpkgs.
  # Bad practices to avoid:
  #   - `nix-env -i`, `sudo nix-channel`, `nix-shell -p <pkg>` (imperative, not reproducible)
  #   - `npm i -g`, `pip install --user`, manual tarballs in ~/.local/bin
  #   - system-wide `environment.systemPackages` for desktop apps (keep that minimal: git/vim/boot tools only)
  # Use per-project shells instead: `nix shell nixpkgs#foo` for one-off try, `nix develop` + flake.nix for dev.
  # ── AI CLIs rule: add the nixpkgs name here, rebuild. No manual ELFs. ──
  home.packages = with pkgs; [
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
    herdr

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
    file # `file -b --mime-type` (webapp-install icon download hard-requires it)

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

    # AI CLIs: available in EVERY shell + GUI session via nix profile
    opencode
    kilo
    nodejs
    bun
    mise
  ];

  # Media keys go through hypr/scripts/osd-volume.sh, osd-brightness.sh and
  # osd-keyboard-brightness.sh (swayosd-client directly) — no wrappers needed.
  home.file.".local/bin/bright" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # bright kbd-up|kbd-down|kbd-cycle — keyboard backlight (noop if none).
      dev=$(brightnessctl -m -c leds -l 2>/dev/null | grep -i kbd | head -n1 | cut -d, -f1)
      [ -n "$dev" ] || exit 0
      case "''${1:-}" in
        kbd-up) exec brightnessctl -d "$dev" set +10% ;;
        kbd-down) exec brightnessctl -d "$dev" set 10%- ;;
        kbd-cycle)
          cur=$(brightnessctl -d "$dev" -m 2>/dev/null | cut -d, -f3)
          if [ -n "$cur" ] && [ "$cur" -gt 0 ] 2>/dev/null; then
            exec brightnessctl -d "$dev" set 0
          else
            exec brightnessctl -d "$dev" set 100%
          fi ;;
        *) exit 0 ;;
      esac
    '';
  };
  home.file.".local/bin/touchpad" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # touchpad [on|off|toggle] — via hyprctl device keyword + state file.
      STATE_DIR="$HOME/.local/state/nixos/toggles"
      mkdir -p "$STATE_DIR"
      name=$(hyprctl devices -j 2>/dev/null | jq -r '[.mice[]? | select(.name | test("touchpad|touch ?pad"; "i"))][0].name // empty')
      [ -n "$name" ] || { echo "no touchpad found" >&2; exit 1; }
      act="''${1:-toggle}"
      if [ "$act" = toggle ]; then
        if [ -f "$STATE_DIR/touchpad-off" ]; then act=on; else act=off; fi
      fi
      case "$act" in
        on) hyprctl keyword "device[$name]:enabled" true >/dev/null && rm -f "$STATE_DIR/touchpad-off" && notify-send "Touchpad" "Enabled" ;;
        off) hyprctl keyword "device[$name]:enabled" false >/dev/null && touch "$STATE_DIR/touchpad-off" && notify-send "Touchpad" "Disabled" ;;
        *) echo "usage: touchpad [on|off|toggle]" >&2; exit 1 ;;
      esac
    '';
  };
  home.file.".local/bin/vol" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # vol cycle-sink — rotate the default PipeWire sink.
      [ "''${1:-}" = cycle-sink ] || { echo "usage: vol cycle-sink" >&2; exit 1; }
      mapfile -t sinks < <(wpctl status 2>/dev/null | awk '
        /Sinks:/ {in_sinks=1; next}
        /Sources:|Filters:|Streams:|Devices:|Sinks *$/ {if (!/Sinks:/) in_sinks=0}
        in_sinks && /[0-9]+\./ {
          line=$0
          current = (line ~ /\*/) ? 1 : 0
          # id: first number before a dot
          match(line, /[0-9]+\./)
          id = substr(line, RSTART, RLENGTH-1)
          gsub(/[^0-9]/, "", id)
          # name: text after "ID. "
          match(line, /[0-9]+\.[[:space:]]*/)
          name = substr(line, RSTART + RLENGTH)
          gsub(/\[vol.*/, "", name)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
          print id "|" current "|" name
        }')
      [ "''${#sinks[@]}" -gt 0 ] || { notify-send "Audio output" "No sinks found"; exit 1; }
      cur_idx=-1
      for i in "''${!sinks[@]}"; do
        IFS='|' read -r _id is_cur _name <<< "''${sinks[$i]}"
        [ "$is_cur" = 1 ] && cur_idx=$i
      done
      if [ "$cur_idx" -ge 0 ]; then
        next_idx=$(( (cur_idx + 1) % ''${#sinks[@]} ))
      else
        next_idx=0
      fi
      IFS='|' read -r next_id _next_cur next_name <<< "''${sinks[$next_idx]}"
      wpctl set-default "$next_id" && notify-send "Audio output" "$next_name"
    '';
  };

  # ── User services: swayosd-server + first-login theme/wallpaper init ──
  systemd.user.services.swayosd = {
    Unit = {
      Description = "SwayOSD on-screen display server";
      # NOTE: there is no hyprland-session.target under uwsm (Hyprland is
      # supervised by uwsm as wayland-wm@*.service). Bind to
      # graphical-session.target, which uwsm does provide — the old
      # hyprland-session.target name meant this unit never started, which is
      # why all XF86 volume/brightness keys were dead.
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
  systemd.user.services.wallpaper-init = {
    Unit = {
      Description = "First-login theme chain + wallpaper + matugen init (Noro)";
      # See swayosd above: graphical-session.target is the uwsm-provided
      # target. The old hyprland-session.target does not exist, so this
      # oneshot never ran → no wallpaper set, matugen never ran →
      # ~/.config/waybar/colors.css missing → waybar crashed on launch.
      After = [ "graphical-session.target" ];
      # Run exactly once; re-run manually via swww-all.sh / picker afterwards.
      ConditionPathExists = "!%h/.local/share/wallpaper-init.done";
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wallpaper-init" ''
        export ACTIVE_THEME=Noro
        ${./modules/theme-chain.sh}
        WALL="$HOME/.local/share/wallpapers/noro/nord-wallpaper.jpg"
        [ -f "$WALL" ] || WALL="$(ls "$HOME"/.local/share/wallpapers/noro/*.jpg "$HOME"/.local/share/wallpapers/noro/*.jpeg 2>/dev/null | head -n1)"
        # awww-daemon is started by Hyprland exec-once; wait for its socket.
        for _i in $(seq 1 60); do
          if [ -S "''${XDG_RUNTIME_DIR:-/run/user/$UID}/awww-''${WAYLAND_DISPLAY:-wayland-1}.socket" ]; then break; fi
          sleep 0.5
        done
        "$HOME/.config/hypr/scripts/swww-all.sh" "$WALL" || true
        mkdir -p "$HOME/.local/share"
        touch "$HOME/.local/share/wallpaper-init.done"
      '';
    };
  };

  # ── Power profile auto-switch: performance on AC, balanced on battery ──
  # `power-profiles autodetect` already implements this policy (with per-source
  # memory in ~/.local/state/power-profiles), but Hyprland autostart only runs
  # it once at login. This path unit re-runs it on every AC plug/unplug.
  systemd.user.services.power-profiles-autoswitch = {
    Unit.Description = "Apply remembered power profile for current AC/battery state";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/power-profiles autodetect";
    };
  };
  systemd.user.paths.power-profiles-autoswitch = {
    Unit.Description = "Watch AC adapter and battery state for power profile switching";
    Install.WantedBy = [ "default.target" ];
    Path = {
      PathChanged = [
        "/sys/class/power_supply/ACAD/online"
        "/sys/class/power_supply/BAT1/status"
      ];
      Unit = "power-profiles-autoswitch.service";
    };
  };
  # Seed AC=performance / battery=balanced defaults (only if user hasn't set
  # their own via `power-profiles set`, which remembers per-source prefs).
  home.activation.seedPowerProfilePrefs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.local/state/power-profiles"
      [ -f "$HOME/.local/state/power-profiles/ac" ] || printf 'performance\n' > "$HOME/.local/state/power-profiles/ac"
      [ -f "$HOME/.local/state/power-profiles/battery" ] || printf 'balanced\n' > "$HOME/.local/state/power-profiles/battery"
    '';

  # ── Packages with NO nixpkgs equivalent (manual step) ──
  # - helium-browser-bin: no nixpkgs package. Option A: Flatpak/WebApp
  #   (`webapp-install` helper already exists). Option B: fetch the upstream
  #   binary tarball with a custom derivation — say the word and I'll write it.
  #   vars.lua currently defaults to chromium, so nothing breaks meanwhile.
  # - voxtype-bin (dictation, F9): not packaged. Install via cargo.
  #   Binds degrade gracefully if missing.
  # - chatgpt-desktop, claude-desktop, cliamp-bin, cloudflare-warp-bin:
  #   cloudflare-warp IS in nixpkgs as `cloudflare-warp` — add it above if you
  #   use WARP. The *-desktop Electron wrappers: use webapp-install or Flatpak.
  # - ttf-joypixels, ttf-material-design-icons-extended, ttf-rubik-vf,
  #   ttf-symbola, otf-aurulent-nerd: nixpkgs has joypixels? No (license).
  #   Use nerd-fonts.* +     noto-fonts-color-emoji; add material-design-icons via
  #   `material-design-icons` font package if glyphs are missing in waybar.

  # ── Shell: zsh (ported from the old shell/zshrc) ──
  # Native instead of symlink: programs.* wires fzf/zoxide/atuin/direnv/starship
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
      # Rebuild from anywhere: absolute flake path, no cd needed.
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#laptop";
    };
    # Matches your custom prompt + LS_COLORS + y() + PATH from shell/zshrc.
    # zsh uses `initContent` on current home-manager (initExtra is deprecated).
    # bash still uses `initExtra` — do NOT rename it (it has no initContent).
    initContent = ''
      export LS_COLORS="di=38;5;45:ln=38;5;75:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32"
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      PROMPT=$'\n%{%F{magenta}%}%{%K{magenta}%}%{%F{black}%}  %{%F{white}%} %~ %{%k%}%{%F{magenta}%}%{%f%}\n%{%F{magenta}%}❯ %{%f%}'
      # Flag nix trial subshells. `nix shell` sets NO marker variable
      # (IN_NIX_SHELL comes only from `nix develop`/legacy nix-shell),
      # and a PATH check is unusable — a normal NixOS session PATH
      # already contains /nix/store entries (binutils/pciutils wrappers…).
      # Instead the try() function below exports NIX_TRY_SHELL, which
      # `nix shell` passes through into the trial shell.
      if [[ -n "''${IN_NIX_SHELL:-}''${NIX_TRY_SHELL:-}" ]]; then
        PROMPT="%{%F{yellow}%}[nix-shell] %{%f%}$PROMPT"
      fi
      RPROMPT=""
      export EDITOR="nvim" VISUAL="nvim"
      export FZF_DEFAULT_OPTS="--height 40% --reverse --border"
      # NOTE: no manual PATH export — home.sessionPath already provides
      # ~/.local/bin, mise shims, ~/.opencode/bin, ~/.kilo/bin.
      # Try any package (incl. unfree) without installing: try nixpkgs#foo
      # Function (not alias) so "$@" passes through and a marker var is
      # set for the prompt: `nix shell` preserves ambient env (only PATH
      # changes), so NIX_TRY_SHELL survives into the trial shell and
      # clears automatically on exit (prefix assignment, parent untouched).
      try() {
        NIXPKGS_ALLOW_UNFREE=1 NIX_TRY_SHELL=1 nix shell --impure "$@"
      }
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
      # Rebuild from anywhere: absolute flake path, no cd needed.
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#laptop";
    };
    initExtra = ''
      # bash on current home-manager still uses `initExtra` (only zsh moved
      # to `initContent`). Keep this name.
      export FZF_DEFAULT_OPTS="--height 40% --reverse --border"
      export EDITOR="nvim" VISUAL="nvim"
      # NOTE: no manual PATH export — home.sessionPath already provides
      # ~/.local/bin. Nix profile bins resolve via /etc/profiles.
      y() {
        local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
        command yazi "$@" --cwd-file="$tmp"
        local cwd="$(cat -- "$tmp" 2>/dev/null)"
        rm -f -- "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
      }
      # Same try() trial-shell helper as zsh (see above): sets
      # NIX_TRY_SHELL for Starship's custom nix-shell module below.
      try() {
        NIXPKGS_ALLOW_UNFREE=1 NIX_TRY_SHELL=1 nix shell --impure "$@"
      }
      eval "$(starship init bash)"
    '';
  };

  programs.fzf = {
    enable = true; # replaces /usr/share/fzf sourcing
    # Atuin owns Ctrl-R; fzf keeps Ctrl-T + Alt-C.
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
  programs.starship = {
    enable = true;
    settings = {
      # Starship's native nix_shell module keys off $IN_NIX_SHELL, which
      # `nix shell` never sets — and a PATH check false-positives, since a
      # normal NixOS session PATH already contains /nix/store entries.
      # Use the NIX_TRY_SHELL marker set by the try() function instead
      # (plus IN_NIX_SHELL for `nix develop`/legacy nix-shell).
      nix_shell.disabled = true;
      custom."nix-shell" = {
        command = "echo nix-shell";
        when = "test -n \"$IN_NIX_SHELL$NIX_TRY_SHELL\"";
        format = "via [$output]($style) ";
        style = "bold yellow";
      };
    };
  };
  programs.git = {
    enable = true;
    settings = {
      # gh auth login stores its token in ~/.config/gh/hosts.yml, but git
      # can't use it until a credential helper feeds it. `store` keeps a
      # ~/.git-credentials file (created once below); HM manages this
      # config file, so `gh auth setup-git` can never write it itself.
      credential.helper = "store";
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

  # ── Portal/GTK settings (dconf) ──
  # GTK4 apps (swayosd, etc.) read org.gnome.desktop.interface from the
  # xdg-desktop-portal Settings backend, which serves dconf — NOT
  # ~/.config/gtk-*/settings.ini. With no dconf db the portal reports
  # icon-theme 'Adwaita'; if that theme isn't installed every lookup fails.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      icon-theme = "Papirus";
      cursor-theme = "Bibata-Modern-Ice";
      cursor-size = 24;
      # Dark web content: the xdg-desktop-portal Settings backend serves
      # this to Chromium/Firefox for prefers-color-scheme, so sites match
      # the dark matugen palette instead of rendering light.
      color-scheme = "prefer-dark";
    };
  };

  # ── Default apps (imv for images, nautilus for folders) ──
  xdg.mimeApps = {    enable = true;
    defaultApplications = {
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
    };
  };

  # Matugen writes generated files (waybar/colors.css, hypr/colors.lua, …)
  # into ~/.config at runtime — modules/<app>/ is only the baseline.
  # Regenerate after changing wallpaper outside the picker:
  #   matugen image ~/.local/share/wallpapers/noro/<pick-one> \
  #     -c ~/.config/matugen/config.toml --source-color-index 0
}
