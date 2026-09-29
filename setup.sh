#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#   setup.sh — minimal NixOS -> this Hyprland desktop.
#   Idempotent: safe to re-run (clone-or-pull, re-link, rebuild).
#
#   Quick start on a fresh minimal NixOS install:
#     git clone https://github.com/rajan9884/nixos-config.git ~/nixos-config
#     ~/nixos-config/setup.sh
#
#   One-liner (same thing, no pre-clone needed):
#     bash <(curl -fsSL https://raw.githubusercontent.com/rajan9884/nixos-config/main/setup.sh)
#
#   Flags:
#     --user NAME        target user (default: current $USER).
#                        The flake hardcodes `rajan`; if TARGET differs the
#                        script rewrites the username in the 3 known files
#                        (flake.nix, home/rajan.nix, hosts/laptop/configuration.nix).
#     --keep-hardware    do NOT regenerate hosts/laptop/hardware-configuration.nix
#                        (default: regenerate from this machine — a fresh
#                        install MUST do this, the committed file is the
#                        author's laptop).
#     --no-rebuild       clone + link + sync only, skip nixos-rebuild.
#     --no-swap          skip the low-RAM swap/parallelism guard.
#     --attr NAME        flake attr (default: laptop).
#     -h|--help          usage.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

NIXOS_REPO="https://github.com/rajan9884/nixos-config.git"
WALLPAPERS_REPO="https://github.com/rajan9884/wallpapers.git"
ATTR="laptop"
TARGET_USER="${USER:-rajan}"
REGENERATE_HARDWARE=1
DO_REBUILD=1
NO_SWAP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --user) TARGET_USER="${2:?--user needs a name}"; shift 2 ;;
    --keep-hardware) REGENERATE_HARDWARE=0; shift ;;
    --no-rebuild) DO_REBUILD=0; shift ;;
    --no-swap) NO_SWAP=1; shift ;;
    --attr) ATTR="${2:?--attr needs a name}"; shift 2 ;;
    -h|--help)
      echo "Usage: setup.sh [--user NAME] [--keep-hardware] [--no-rebuild] [--no-swap] [--attr NAME]"
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

log() { printf '==> %s\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }

# ── 0. Sanity: NixOS, non-root, sudo ─────────────────────────
if [ ! -e /etc/NIXOS ] && ! grep -qs 'ID=nixos' /etc/os-release 2>/dev/null; then
  warn "this script is for NixOS (not detected). Aborting."
  exit 1
fi
if [ "$(id -u)" -eq 0 ]; then
  warn "run as your normal user (with sudo rights), NOT as root."
  exit 1
fi
# Refuse the minimal-ISO installer shell: this script deploys onto a booted
# INSTALLED system (it rebuilds / and symlinks /etc/nixos). On the ISO,
# finish mounting + nixos-install + reboot first (see INSTALL.md).
if [ "$(findmnt -n -o FSTYPE / 2>/dev/null)" = tmpfs ] \
  || grep -qs 'VARIANT.*[Ii]nstaller' /etc/os-release 2>/dev/null; then
  warn "you're in the installer live environment, not the installed system."
  warn "Here, do only: nixos-generate-config --root /mnt, edit the minimal"
  warn "config, nixos-install, reboot — THEN run setup.sh. See INSTALL.md."
  exit 1
fi
command -v sudo >/dev/null || { warn "sudo is required."; exit 1; }

# Where does this checkout live? Prefer the real script dir (clone-first
# flow); fall back to ~/nixos-config (curl one-liner flow, clone below).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || pwd)"
if [ -f "$SCRIPT_DIR/flake.nix" ]; then
  CONFIG_DIR="$SCRIPT_DIR"
else
  CONFIG_DIR="$HOME/nixos-config"
fi
WALL_DIR="$HOME/wallpapers"

# ── 1. git ────────────────────────────────────────────────────
if ! command -v git >/dev/null; then
  log "git not found — installing to current profile…"
  nix-env -iA nixpkgs.git
fi

# ── 2. Clone (or update) both repos ───────────────────────────
if [ -d "$CONFIG_DIR/.git" ]; then
  log "nixos-config exists — pulling latest…"
  git -C "$CONFIG_DIR" pull --ff-only || warn "pull failed, keeping local checkout"
else
  log "cloning nixos-config -> $CONFIG_DIR"
  git clone "$NIXOS_REPO" "$CONFIG_DIR"
fi
if [ -d "$WALL_DIR/.git" ]; then
  log "wallpapers exists — pulling latest…"
  git -C "$WALL_DIR" pull --ff-only || warn "pull failed, keeping local checkout"
else
  log "cloning wallpapers -> $WALL_DIR"
  git clone "$WALLPAPERS_REPO" "$WALL_DIR"
fi

# ── 3. Flatten wallpapers NOW (so the flat store exists pre-rebuild) ──
log "flatten-copying wallpapers -> ~/.local/share/wallpapers (no subdirs)…"
bash "$CONFIG_DIR/modules/home/bin/wallpapers-sync" --src "$WALL_DIR"

# ── 4. Hardware config: MUST match this machine ───────────────
HW="$CONFIG_DIR/hosts/$ATTR/hardware-configuration.nix"
if [ "$REGENERATE_HARDWARE" -eq 1 ]; then
  log "regenerating $HW from this machine…"
  [ -f "$HW" ] && cp -f "$HW" "$HW.bak-$(date +%Y%m%d-%H%M%S)"
  sudo nixos-generate-config --show-hardware-config > "$HW"
else
  log "keeping existing $HW (--keep-hardware)"
fi

# ── 5. Username: flake hardcodes `rajan` ──────────────────────
if [ "$TARGET_USER" != "rajan" ]; then
  log "rewriting hardcoded user 'rajan' -> '$TARGET_USER' in 3 files…"
  sed -i "s/home-manager\.users\.rajan/home-manager.users.$TARGET_USER/" "$CONFIG_DIR/flake.nix"
  sed -i -e "s/home\.username = \"rajan\"/home.username = \"$TARGET_USER\"/" \
         -e "s|home\.homeDirectory = \"/home/rajan\"|home.homeDirectory = \"/home/$TARGET_USER\"|" \
         -e "s|/home/rajan/nixos-config|/home/$TARGET_USER/nixos-config|g" \
    "$CONFIG_DIR/home/rajan.nix"
  sed -i -e "s/users\.users\.rajan/users.users.$TARGET_USER/" \
         -e "s|/home/rajan/nixos-config|/home/$TARGET_USER/nixos-config|" \
    "$CONFIG_DIR/hosts/$ATTR/configuration.nix"
  grep -rn "rajan" "$CONFIG_DIR/flake.nix" "$CONFIG_DIR/home/rajan.nix" \
    "$CONFIG_DIR/hosts/$ATTR/configuration.nix" | grep -v "rajan9884\|rj\.vidyagyan\|description\|home/rajan\.nix" \
    && { warn "leftover 'rajan' above — fix manually before rebuilding"; exit 1; }
  log "username rewrite clean."
fi

# ── 6. /etc/nixos -> ~/nixos-config (compat symlink) ──────────
if [ -L /etc/nixos ] && [ "$(readlink /etc/nixos)" = "$CONFIG_DIR" ]; then
  log "/etc/nixos already links to $CONFIG_DIR"
else
  log "linking /etc/nixos -> $CONFIG_DIR"
  if [ -e /etc/nixos ] || [ -L /etc/nixos ]; then
    sudo mv /etc/nixos "/etc/nixos.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  sudo ln -s "$CONFIG_DIR" /etc/nixos
fi

# ── 7. Low-RAM guard: swap + constrained parallelism ────────
# A full Hyprland closure from nixos-unstable OOMs on <8GB RAM with Nix's
# default (one build job per core, each Rust/C++ link eating GBs). This is
# the classic first-install "out of memory" killer — not a bad command and
# not a broken nix. Ensure swap exists, then cap parallelism for rebuilds.
REBUILD_FLAGS=()
if [ "$NO_SWAP" -eq 0 ]; then
  MEM_GB=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)
  SWAP_KB=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
  if [ "$MEM_GB" -lt 8 ]; then
    MAX_JOBS=2; CORES=2
    [ "$MEM_GB" -le 4 ] && MAX_JOBS=1
    REBUILD_FLAGS=(--max-jobs "$MAX_JOBS" --cores "$CORES")
    log "low RAM (${MEM_GB}GB): rebuilding with --max-jobs $MAX_JOBS --cores $CORES"
  fi
  if [ "${SWAP_KB:-0}" -lt 4194304 ]; then
    if [ -f /swapfile ]; then
      log "activating existing /swapfile…"
      sudo swapon /swapfile 2>/dev/null || true
    elif [ "$(df -BG --output=avail / | tail -1 | tr -dc '0-9')" -lt 10 ]; then
      warn "low disk space (<10GB free on /) — skipping swapfile creation."
      warn "Free disk space or the build may fail with 'No space left on device'."
    else
      log "creating 8GB /swapfile (low-RAM safety net)…"
      sudo fallocate -l 8G /swapfile 2>/dev/null \
        || sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=none
      sudo chmod 600 /swapfile
      sudo mkswap /swapfile >/dev/null
      sudo swapon /swapfile
      grep -qs '^/swapfile' /etc/fstab \
        || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
    fi
  else
    log "swap OK ($(awk '/SwapTotal/ {printf "%dGB", $2/1024/1024}' /proc/meminfo))"
  fi
fi

# ── 8. Rebuild ────────────────────────────────────────────────
if [ "$DO_REBUILD" -eq 1 ]; then
  log "switching: nixos-rebuild switch --flake $CONFIG_DIR#$ATTR ${REBUILD_FLAGS[*]}"
  # shellcheck disable=SC2068
  sudo nixos-rebuild switch --flake "$CONFIG_DIR#$ATTR" ${REBUILD_FLAGS[@]+"${REBUILD_FLAGS[@]}"}
else
  log "skipping rebuild (--no-rebuild)"
fi

# ── 9. Next steps ─────────────────────────────────────────────
cat <<EOF
==> done.
Next (once, after first login via tuigreet):
  ACTIVE_THEME=Noro ~/.config/hypr/theme-chain.sh
  reboot, log in, pick a wallpaper:  <Super>+W  (or: wallpapers-sync after git pull)
Daily:  nrs (switch) · nrb (build) · nrc (stage + flake check)
EOF
