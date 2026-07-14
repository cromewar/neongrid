#!/usr/bin/env bash
# ============================================================================
#  NEONGRID — one-line network installer.
#
#      bash <(curl -fsSL https://neongrid.sh)          # if you alias it
#      curl -fsSL https://raw.githubusercontent.com/cromewar/neongrid/master/net-install.sh | bash
#
#  Clones the repo to ~/cyberdeck and hands off to the TUI.
#  Non-interactive:  ... | bash -s -- --yes        (full install, no menu)
#                    ... | bash -s -- --dry-run    (show everything, change nothing)
# ============================================================================
set -euo pipefail

REPO_URL="https://github.com/cromewar/neongrid.git"
DEST="${NEONGRID_DIR:-$HOME/cyberdeck}"

G=$'\e[1;92m'; Y=$'\e[1;93m'; R=$'\e[1;91m'; D=$'\e[2m'; N=$'\e[0m'
die() { printf '%s ✗ %s%s\n' "$R" "$1" "$N" >&2; exit 1; }
say() { printf '%s▸%s %s\n' "$G" "$N" "$1"; }

printf '\n%s' "$G"
cat <<'BANNER'
   ███╗   ██╗███████╗ ██████╗ ███╗   ██╗ ██████╗ ██████╗ ██╗██████╗
   ████╗  ██║██╔════╝██╔═══██╗████╗  ██║██╔════╝ ██╔══██╗██║██╔══██╗
   ██╔██╗ ██║█████╗  ██║   ██║██╔██╗ ██║██║  ███╗██████╔╝██║██║  ██║
   ██║╚██╗██║██╔══╝  ██║   ██║██║╚██╗██║██║   ██║██╔══██╗██║██║  ██║
   ██║ ╚████║███████╗╚██████╔╝██║ ╚████║╚██████╔╝██║  ██║██║██████╔╝
   ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝
BANNER
printf '%s' "$N"
printf '   %scyberpunk desktop · CachyOS · KDE Plasma 6 · Wayland%s\n\n' "$D" "$N"

# ── preflight ───────────────────────────────────────────────────────────────
[ -f /etc/arch-release ] || grep -qi 'ID_LIKE=.*arch' /etc/os-release 2>/dev/null \
  || die "Arch-based distro required (CachyOS / Arch / EndeavourOS)."
command -v plasmashell >/dev/null || die "KDE Plasma not found."
[ "$(id -u)" -ne 0 ] || die "Do NOT run this as root. It asks for sudo once, itself."

if ! command -v git >/dev/null; then
  say "installing git"
  sudo pacman -S --needed --noconfirm git
fi

# ── fetch ───────────────────────────────────────────────────────────────────
if [ -d "$DEST/.git" ]; then
  say "updating $DEST"
  git -C "$DEST" pull --ff-only || printf '%s  ! local changes — keeping them%s\n' "$Y" "$N"
elif [ -e "$DEST" ]; then
  die "$DEST exists and is not a git repo. Move it aside first."
else
  say "cloning into $DEST"
  git clone --depth 1 "$REPO_URL" "$DEST"
fi

cd "$DEST"
chmod +x ./*.sh 2>/dev/null || true

# ── hand off ────────────────────────────────────────────────────────────────
# When piped from curl, stdin is the SCRIPT, not the keyboard — an interactive
# menu would read the script's own bytes as keystrokes. Reattach the terminal.
if [ ! -t 0 ] && [ -r /dev/tty ]; then
  exec < /dev/tty
fi

if [ $# -gt 0 ]; then
  exec ./install-tui.sh "$@"       # --yes / --dry-run passed straight through
elif [ -t 0 ]; then
  exec ./install-tui.sh            # interactive menu
else
  # no terminal at all (CI, no /dev/tty): fall back to a safe dry run
  printf '%s  ! no terminal available — running --dry-run. Re-run with --yes to install.%s\n' "$Y" "$N"
  exec ./install-tui.sh --dry-run
fi
