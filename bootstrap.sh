#!/usr/bin/env bash
# ============================================================================
#  NEONGRID — one-shot bootstrap for a fresh machine.
#
#  Usage:   ./bootstrap.sh            (full install)
#           ./bootstrap.sh --dry-run  (show what would happen, change nothing)
#
#  Asks for your password EXACTLY ONCE: `sudo -v` caches the credential and a
#  keepalive refreshes it for the life of the script, so pacman/paru/install
#  never prompt again.
#
#  Idempotent: safe to re-run. Every destructive step backs up first.
# ============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

G=$'\e[1;92m'; Y=$'\e[1;93m'; R=$'\e[1;91m'; D=$'\e[2m'; N=$'\e[0m'
step() { printf '\n%s▶ %s%s\n' "$G" "$1" "$N"; }
warn() { printf '%s  ! %s%s\n' "$Y" "$1" "$N"; }
die()  { printf '%s  ✗ %s%s\n' "$R" "$1" "$N" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then printf '%s    would run: %s%s\n' "$D" "$*" "$N"; else "$@"; fi; }

# ── 0. preflight ────────────────────────────────────────────────────────────
step "Preflight"
[ -f /etc/arch-release ] || grep -qi 'ID_LIKE=.*arch' /etc/os-release \
  || die "This targets Arch-based distros (CachyOS/Arch/EndeavourOS)."
command -v plasmashell >/dev/null || die "KDE Plasma not found."
PLASMA="$(plasmashell --version | grep -oE '[0-9]+\.[0-9]+' | head -1)"
printf '  distro : %s\n' "$(. /etc/os-release; echo "$PRETTY_NAME")"
printf '  plasma : %s\n' "$PLASMA"
printf '  session: %s\n' "${XDG_SESSION_TYPE:-unknown}"
[ "${XDG_SESSION_TYPE:-}" = "wayland" ] || warn "Not a Wayland session — Better Blur DX is Wayland-only; blur will not work."
case "$PLASMA" in
  6.*) ;;
  *) die "Plasma 6 required (found $PLASMA)." ;;
esac

# What this machine actually has decides what we theme. Note /boot is usually
# root-only, so probe /etc/default/limine (readable) rather than /boot.
HAS_LIMINE=0
if [ -f /etc/default/limine ] || pacman -Qq limine >/dev/null 2>&1; then HAS_LIMINE=1; fi
HAS_PLM=0
if systemctl list-unit-files plasmalogin.service >/dev/null 2>&1 \
   && systemctl list-unit-files plasmalogin.service 2>/dev/null | grep -q plasmalogin; then HAS_PLM=1; fi
HAS_PLYMOUTH=0
if command -v plymouth-set-default-theme >/dev/null 2>&1; then HAS_PLYMOUTH=1; fi
printf '  limine : %s | plasmalogin: %s | plymouth: %s\n' \
  "$([ $HAS_LIMINE = 1 ] && echo yes || echo 'no (bootloader theming skipped)')" \
  "$([ $HAS_PLM = 1 ] && echo yes || echo 'no (live login screen skipped)')" \
  "$([ $HAS_PLYMOUTH = 1 ] && echo yes || echo 'no (boot splash skipped)')"

# ── 1. THE ONLY PASSWORD PROMPT ─────────────────────────────────────────────
step "Authenticating (this is the only password prompt)"
if [ "$DRY" = 0 ]; then
  sudo -v || die "sudo failed"
  # Keep the credential warm so nothing prompts again mid-build.
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 45; done ) 2>/dev/null &
  KEEPALIVE=$!
  trap 'kill "$KEEPALIVE" 2>/dev/null || true' EXIT
fi

# ── 2. snapshot ─────────────────────────────────────────────────────────────
step "Safety snapshot"
if command -v snapper >/dev/null && sudo snapper list-configs 2>/dev/null | grep -q root; then
  run sudo snapper -c root create -d "pre-neongrid"
  echo "  snapper snapshot taken (rollback from the boot menu if needed)"
else
  warn "snapper not configured — no snapshot. Your call whether to continue."
fi
mkdir -p "$REPO/backup"
for f in kdeglobals kwinrc kcminputrc plasma-org.kde.plasma.desktop-appletsrc; do
  [ -f "$HOME/.config/$f" ] && cp -a "$HOME/.config/$f" "$REPO/backup/$f.orig" 2>/dev/null || true
done
[ -d "$HOME/.config/gtk-3.0" ] && cp -a "$HOME/.config/gtk-3.0" "$REPO/backup/" 2>/dev/null || true
echo "  configs backed up to $REPO/backup/"

# ── 3. packages ─────────────────────────────────────────────────────────────
step "Packages"
if ! command -v paru >/dev/null; then
  warn "paru missing — building it (needed for the AUR components)"
  run sudo pacman -S --needed --noconfirm base-devel git
  if [ "$DRY" = 0 ]; then
    tmp=$(mktemp -d); git clone -q https://aur.archlinux.org/paru-bin.git "$tmp/paru"
    ( cd "$tmp/paru" && makepkg -si --noconfirm )
    rm -rf "$tmp"
  fi
fi

run sudo pacman -S --needed --noconfirm \
  ttf-jetbrains-mono-nerd inter-font starship vivid cava imagemagick \
  adw-gtk-theme xdg-desktop-portal-gtk kde-gtk-config \
  nodejs npm python cmake extra-cmake-modules git curl

# paru must never run as root; sudo is already cached so it will not prompt.
run paru -S --needed --noconfirm \
  ttf-rajdhani ttf-orbitron beautyline colloid-icon-theme-git darkly-bin \
  python-clickgen klassy-git kwin-effects-better-blur-dx \
  plasma6-applets-panel-colorizer

# ── 4. generated theme assets ───────────────────────────────────────────────
step "Generating theme from palette.sh"
run bash "$REPO/kde/gen-colors.sh"
run bash "$REPO/kde/gen-colors.sh" --light
run bash "$REPO/kde/gen-lookandfeel.sh"
run python3 "$REPO/kde/gen-desktoptheme.py"
run bash "$REPO/ghostty/gen-theme.sh"
run bash "$REPO/ghostty/gen-shader.sh"
run bash "$REPO/gtk/gen-gtk.sh"
run bash "$REPO/shell/gen-shell.sh"

step "Icon theme (hue-snap + brand marks)"
run python3 "$REPO/icons/hue-snap.py"     # whole theme into palette, gradients kept
run bash "$REPO/icons/gen-icons.sh"       # real vector brand marks per app

step "Cursor"
if [ ! -d "$REPO/cursor/Bibata-Neon" ]; then
  run bash "$REPO/cursor/build-bibata.sh"
else
  echo "  Bibata-Neon already built (in repo)"
fi

# ── 5. shader wallpaper (build from source; not in the AUR) ─────────────────
step "Shader wallpaper"
SHADER_SRC="$REPO/.build-shader"
if [ ! -d "$SHADER_SRC" ]; then
  run git clone --depth 1 https://github.com/y4my4my4m/kde-shader-wallpaper.git "$SHADER_SRC"
fi
run env INSTALL_PREFIX=/usr BUILD_TYPE=Release bash "$SHADER_SRC/scripts/build.sh" build
run bash "$REPO/wallpapers/gen-wallpaper-shader.sh"
run bash "$REPO/wallpapers/gen-wallpaper-shader.sh" --light

# ── 6. apply KDE ────────────────────────────────────────────────────────────
step "Applying KDE (colors, Darkly, Klassy, blur, fonts, icons)"
run bash "$REPO/kde/apply.sh"
run bash "$REPO/kde/apply-klassy.sh"
run bash "$REPO/kde/apply-effects.sh"
run kwriteconfig6 --file kdeglobals --group Icons --key Theme NeonGrid
run kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Bibata-Neon
run kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24

# ── 7. privileged batch (no prompt — credential is cached) ──────────────────
step "System files (cursor, wallpaper plugin, greeter, boot)"

# cursor must live in /usr: some Wayland/GTK clients cannot see ~/.local/share/icons
run sudo rm -rf /usr/share/icons/Bibata-Neon
run sudo cp -r "$REPO/cursor/Bibata-Neon" /usr/share/icons/

# wallpaper plugin system-wide — REQUIRED for the login greeter to use it
run sudo make -C "$SHADER_SRC/build" install
run rm -rf "$HOME/.local/share/plasma/wallpapers/online.knowmad.shaderwallpaper"

if [ "$HAS_PLM" = 1 ]; then
  # plasmalogin cannot use QML themes at all — its ONLY appearance hook is
  # WallpaperPluginId. That single key buys us a live animated greeter.
  run sudo bash "$SHADER_SRC/scripts/install-plm-greeter.sh" || warn "PLM greeter helper failed (non-fatal)"
  if [ "$DRY" = 0 ]; then
    sudo cp -a /etc/plasmalogin.conf "$REPO/backup/plasmalogin.conf.orig" 2>/dev/null || true
    grep -q '^\[Greeter\]' /etc/plasmalogin.conf 2>/dev/null || echo -e '\n[Greeter]' | sudo tee -a /etc/plasmalogin.conf >/dev/null
    if grep -q '^WallpaperPluginId=' /etc/plasmalogin.conf; then
      sudo sed -i 's|^WallpaperPluginId=.*|WallpaperPluginId=online.knowmad.shaderwallpaper|' /etc/plasmalogin.conf
    else
      sudo sed -i '/^\[Greeter\]/a WallpaperPluginId=online.knowmad.shaderwallpaper' /etc/plasmalogin.conf
    fi
    echo "  login greeter -> shader wallpaper"
  fi
fi

if [ "$HAS_PLYMOUTH" = 1 ]; then
  run bash "$REPO/boot/gen-plymouth.sh"
  run sudo rm -rf /usr/share/plymouth/themes/neongrid
  run sudo cp -r "$REPO/boot/plymouth/neongrid" /usr/share/plymouth/themes/
  run sudo plymouth-set-default-theme -R neongrid
fi

if [ "$HAS_LIMINE" = 1 ] && [ -f /boot/limine.conf ]; then
  # A malformed limine.conf = an unbootable machine. Back up, touch only the
  # GLOBAL styling keys (limine-entry-tool owns the entries), verify the entry
  # count survived, and re-enroll the checksum if enrollment is in use.
  if [ "$DRY" = 0 ]; then
    source "$REPO/palette.sh"
    sudo cp -a /boot/limine.conf /boot/limine.conf.neongrid-backup
    BEFORE=$(grep -c '^/' /boot/limine.conf || true)
    sudo sed -i '/^# >>> NEONGRID/,/^# <<< NEONGRID/d' /boot/limine.conf
    sudo tee /tmp/ng-limine >/dev/null <<EOF
# >>> NEONGRID
timeout: 3
term_background: 00${BG}
term_foreground: ${GREEN_HERO}
term_palette: ${SURFACE};${RED};${GREEN};${YELLOW};${VIOLET};${MAGENTA};${CYAN};${WHITE}
term_palette_bright: ${BLACK_BR};${RED_BR};${GREEN_HERO};${YELLOW_BR};${VIOLET_BR};${MAGENTA_BR};${CYAN_BR};${WHITE_BR}
interface_branding_colour: ${VIOLET}
interface_branding: // N E O N G R I D
interface_help_colour: ${GREEN_HERO}
term_margin: 48
# <<< NEONGRID
EOF
    sudo bash -c 'cat /boot/limine.conf >> /tmp/ng-limine && mv /tmp/ng-limine /boot/limine.conf && chmod 644 /boot/limine.conf'
    AFTER=$(grep -c '^/' /boot/limine.conf || true)
    if [ "$BEFORE" != "$AFTER" ]; then
      warn "boot entries changed ($BEFORE -> $AFTER) — RESTORING backup"
      sudo cp -a /boot/limine.conf.neongrid-backup /boot/limine.conf
    else
      echo "  limine styled; boot entries intact ($AFTER)"
      command -v limine-enroll-config >/dev/null && sudo limine-enroll-config 2>/dev/null || true
    fi
  fi
fi

# rebuild reminder for the three compiled components
run sudo install -Dm644 "$REPO/hooks/95-neongrid-rebuild.hook" \
  /etc/pacman.d/hooks/95-neongrid-rebuild.hook

# ── 8. Ghostty ──────────────────────────────────────────────────────────────
step "Ghostty"
run mkdir -p "$HOME/.config/ghostty"
run ln -sfn "$REPO/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
run ln -sfn "$REPO/ghostty/themes"  "$HOME/.config/ghostty/themes"
run ln -sfn "$REPO/ghostty/shaders" "$HOME/.config/ghostty/shaders"
if [ "$DRY" = 0 ] && command -v ghostty >/dev/null; then
  ghostty +validate-config >/dev/null 2>&1 && echo "  config valid" || warn "ghostty config did not validate"
fi

# ── 9. shell ────────────────────────────────────────────────────────────────
step "Shell"
if [ "$DRY" = 0 ] && ! grep -q NEONGRID "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" <<EOF

# ---------------- NEONGRID ----------------
source $REPO/shell/neongrid-env.sh
eval "\$(starship init zsh)"
EOF
  echo "  zsh wired to starship + palette"
fi
FISH_RC="$HOME/.config/fish/config.fish"
if [ "$DRY" = 0 ] && [ -f "$FISH_RC" ] && ! grep -q NEONGRID "$FISH_RC"; then
  cat >> "$FISH_RC" <<EOF

# ---------------- NEONGRID ----------------
if status is-interactive
    source $REPO/shell/neongrid-env.fish
    starship init fish | source
end
EOF
  echo "  fish wired to starship + palette"
fi

# ── 10. panel + wallpaper (needs a live plasmashell) ────────────────────────
step "Panel and wallpaper"
if [ "$DRY" = 0 ]; then
  bash "$REPO/kde/install-plasmoids.sh"
  bash "$REPO/kde/apply-layout.sh" || warn "panel layout script failed (is plasmashell running?)"
  sleep 2
  python3 "$REPO/kde/apply-panel.py"
  bash "$REPO/kde/apply-wallpaper.sh" || warn "wallpaper apply failed"
  bash "$REPO/kde/apply-lockscreen.sh" || warn "lock screen apply failed"
  echo "  panel + shader wallpaper + lock screen configured"
fi

# ── 11. reload ──────────────────────────────────────────────────────────────
step "Reloading"
run rm -f "$HOME/.cache/icon-cache.kcache"
if [ "$DRY" = 0 ]; then
  qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
  systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
  sleep 5
  pgrep -x plasmashell >/dev/null && echo "  plasmashell alive" || warn "plasmashell is not running — see README recovery"
fi

cat <<EOF

${G}NEONGRID installed.${N}

  ${Y}LOG OUT AND BACK IN.${N} Klassy reads its config only when KWin starts, so the
  neon window outline and green glow shadow will NOT appear until you do.

  After any Plasma update run:  ${G}$REPO/rebuild.sh${N}
  (better-blur-dx / klassy / panel-colorizer are compiled against KWin internals;
   skip the rebuild and you lose blur, window decorations, or plasmashell itself.)

EOF
