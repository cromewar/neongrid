#!/usr/bin/env bash
# ============================================================================
#  NEONGRID — installer TUI.
#
#      ./install-tui.sh              interactive menu
#      ./install-tui.sh --yes        full install, no prompts
#      ./install-tui.sh --dry-run    show everything, change nothing
#
#  Zero dependencies on purpose: no gum, no dialog, no whiptail. A fresh machine
#  has none of them, and making the installer install its own installer is silly.
# ============================================================================
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

# palette (the theme's own colours, naturally)
GRN=$'\e[38;2;57;255;20m'; GRN2=$'\e[38;2;59;224;92m'
VIO=$'\e[38;2;157;107;255m'; MAG=$'\e[38;2;217;107;255m'
RED=$'\e[38;2;255;60;106m'; DIM=$'\e[2m'; B=$'\e[1m'; N=$'\e[0m'
CLR=$'\e[2J\e[H'

MODE=""
for a in "$@"; do
  case "$a" in
    --yes|-y)   MODE=install ;;
    --dry-run)  MODE=dry ;;
    --help|-h)  printf 'usage: %s [--yes|--dry-run]\n' "$0"; exit 0 ;;
  esac
done

banner() {
  printf '%s%s' "$CLR" "$GRN"
  cat <<'BANNER'
   ███╗   ██╗███████╗ ██████╗ ███╗   ██╗ ██████╗ ██████╗ ██╗██████╗
   ████╗  ██║██╔════╝██╔═══██╗████╗  ██║██╔════╝ ██╔══██╗██║██╔══██╗
   ██╔██╗ ██║█████╗  ██║   ██║██╔██╗ ██║██║  ███╗██████╔╝██║██║  ██║
   ██║╚██╗██║██╔══╝  ██║   ██║██║╚██╗██║██║   ██║██╔══██╗██║██║  ██║
   ██║ ╚████║███████╗╚██████╔╝██║ ╚████║╚██████╔╝██║  ██║██║██████╔╝
   ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝
BANNER
  printf '%s   %scyberpunk desktop%s %s·%s CachyOS %s·%s KDE Plasma 6 %s·%s Wayland\n\n' \
    "$N" "$VIO" "$N" "$DIM" "$N" "$DIM" "$N" "$DIM" "$N"
}

# ── what this machine is ────────────────────────────────────────────────────
detect() {
  DISTRO="$(. /etc/os-release; echo "$PRETTY_NAME")"
  PLASMA="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  SESSION="${XDG_SESSION_TYPE:-unknown}"
  HAS_LIMINE=no;   { [ -f /etc/default/limine ] || pacman -Qq limine >/dev/null 2>&1; } && HAS_LIMINE=yes
  HAS_PLM=no;      systemctl list-unit-files plasmalogin.service 2>/dev/null | grep -q plasmalogin && HAS_PLM=yes
  HAS_PLYMOUTH=no; command -v plymouth-set-default-theme >/dev/null 2>&1 && HAS_PLYMOUTH=yes
  GPU="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | sed 's/.*: //' | cut -c1-46)"
}

row() { printf '   %s%-14s%s %s\n' "$DIM" "$1" "$N" "$2"; }
ok()  { printf '%s%s%s' "$GRN2" "$1" "$N"; }
no()  { printf '%s%s%s' "$DIM" "$1" "$N"; }

summary() {
  printf '   %s┌─ system ─────────────────────────────────────────────%s\n' "$VIO" "$N"
  row "distro"   "$DISTRO"
  row "plasma"   "$PLASMA"
  row "session"  "$([ "$SESSION" = wayland ] && ok wayland || printf '%s%s (blur needs Wayland)%s' "$RED" "$SESSION" "$N")"
  row "gpu"      "$GPU"
  printf '   %s├─ optional layers ────────────────────────────────────%s\n' "$VIO" "$N"
  row "bootloader" "$([ "$HAS_LIMINE" = yes ] && ok 'limine — boot menu will be themed' || no 'no limine — skipped')"
  row "login"      "$([ "$HAS_PLM" = yes ] && ok 'plasmalogin — animated greeter' || no 'no plasmalogin — skipped')"
  row "splash"     "$([ "$HAS_PLYMOUTH" = yes ] && ok 'plymouth — neon boot splash' || no 'no plymouth — skipped')"
  printf '   %s└──────────────────────────────────────────────────────%s\n\n' "$VIO" "$N"
}

what_it_does() {
  printf '   %sIt will:%s\n' "$B" "$N"
  printf '     %s·%s install ~15 packages (repo + AUR: klassy, better-blur-dx, darkly…)\n' "$GRN" "$N"
  printf '     %s·%s build a neon cursor, an icon theme, and a GLSL wallpaper from source\n' "$GRN" "$N"
  printf '     %s·%s theme KDE, GTK, Ghostty, the shell, the boot splash and the login screen\n' "$GRN" "$N"
  printf '     %s·%s take a snapper snapshot first, and back up your configs to backup/\n' "$GRN" "$N"
  printf '\n   %sAsks for your password %sexactly once%s%s.%s\n\n' "$DIM" "$B" "$N" "$DIM" "$N"
}

confirm() {
  printf '   %s▶%s Install now? %s[y/N]%s ' "$GRN" "$N" "$DIM" "$N"
  read -r a
  [[ "$a" =~ ^[Yy]$ ]]
}

run_install() { exec ./bootstrap.sh; }
run_dry()     { exec ./bootstrap.sh --dry-run; }

# ── non-interactive paths ───────────────────────────────────────────────────
case "$MODE" in
  install) detect; banner; summary; run_install ;;
  dry)     detect; banner; summary; run_dry ;;
esac

# ── menu ────────────────────────────────────────────────────────────────────
detect
while true; do
  banner
  summary
  printf '   %s1%s  Install everything        %s(recommended)%s\n' "$GRN" "$N" "$DIM" "$N"
  printf '   %s2%s  Dry run                   %s(show every action, change nothing)%s\n' "$GRN" "$N" "$DIM" "$N"
  printf '   %s3%s  Install one layer         %s(kde · gtk · ghostty · shell · panel · cursor · boot)%s\n' "$GRN" "$N" "$DIM" "$N"
  printf '   %s4%s  What will it change?      %s(read before you commit)%s\n' "$GRN" "$N" "$DIM" "$N"
  printf '   %sq%s  Quit\n\n' "$MAG" "$N"
  printf '   %s▶%s ' "$GRN" "$N"
  read -r choice

  case "$choice" in
    1) banner; summary; what_it_does; confirm && run_install || continue ;;
    2) run_dry ;;
    3)
      printf '\n   layer %s[kde|gtk|ghostty|shell|panel|cursor|boot]%s: ' "$DIM" "$N"
      read -r layer
      case "$layer" in
        kde|gtk|ghostty|shell|panel|cursor|boot) exec ./install.sh --only "$layer" ;;
        *) printf '   %sunknown layer%s\n' "$RED" "$N"; sleep 1 ;;
      esac ;;
    4)
      banner; what_it_does
      printf '   %sNothing is irreversible:%s\n' "$B" "$N"
      printf '     %s·%s a snapper snapshot is taken before any package is installed\n' "$VIO" "$N"
      printf '     %s·%s your KDE/GTK configs are copied to %sbackup/%s first\n' "$VIO" "$N" "$B" "$N"
      printf '     %s·%s the bootloader config is backed up and the entry count re-verified;\n' "$VIO" "$N"
      printf '       if it changed at all, the backup is restored automatically\n'
      printf '\n   %sAfter install: log out and back in%s — Klassy reads its config only\n' "$B" "$N"
      printf '   when KWin starts, so the window glow appears on the next session.\n\n'
      printf '   %spress enter%s ' "$DIM" "$N"; read -r _ ;;
    q|Q) printf '\n   nothing changed.\n\n'; exit 0 ;;
  esac
done
