#!/usr/bin/env bash
# NEONGRID — everything that genuinely needs root, in ONE pass.
# Run via: pkexec bash ~/cyberdeck/install-root.sh <your-username>
#
# Everything else in this repo is user-level and needs no privileges.
set -euo pipefail

REAL_USER="${1:-${SUDO_USER:-${PKEXEC_UID:+$(id -un "$PKEXEC_UID")}}}"
[ -n "${REAL_USER:-}" ] || { echo "usage: install-root.sh <username>" >&2; exit 1; }
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"
REPO="$HOME_DIR/cyberdeck"
source "$REPO/palette.sh"

say() { printf '\n\033[1;92m▶ %s\033[0m\n' "$1"; }

# ── 1. cursor ───────────────────────────────────────────────────────────
# /usr, not ~/.local/share/icons — some Wayland/GTK clients cannot see cursor
# themes in the user dir.
say "Installing Bibata-Neon cursor to /usr/share/icons"
rm -rf /usr/share/icons/Bibata-Neon
cp -r "$REPO/cursor/Bibata-Neon" /usr/share/icons/
gtk-update-icon-cache -f /usr/share/icons/Bibata-Neon 2>/dev/null || true

# ── 2. shader wallpaper (system-wide: required for the PLM greeter) ─────
say "Installing shader wallpaper plugin system-wide"
make -C "$REPO/.build-shader/build" install >/dev/null
# A ~/.local copy would shadow /usr in the desktop wallpaper picker.
rm -rf "$HOME_DIR/.local/share/plasma/wallpapers/online.knowmad.shaderwallpaper"

# ── 3. login greeter ────────────────────────────────────────────────────
# plasmalogin cannot use QML themes at all — its ONLY appearance hook is
# WallpaperPluginId. That one key is enough to give it a live GLSL background,
# which is something SDDM structurally cannot do.
say "Enabling shader wallpaper on the plasmalogin greeter"
bash "$REPO/.build-shader/scripts/install-plm-greeter.sh" 2>&1 | tail -3 || true

PLM=/etc/plasmalogin.conf
cp -a "$PLM" "$REPO/backup/plasmalogin.conf.orig" 2>/dev/null || true
if ! grep -q "^\[Greeter\]" "$PLM" 2>/dev/null; then
  printf '\n[Greeter]\n' >> "$PLM"
fi
if grep -q "^WallpaperPluginId=" "$PLM"; then
  sed -i 's|^WallpaperPluginId=.*|WallpaperPluginId=online.knowmad.shaderwallpaper|' "$PLM"
else
  sed -i '/^\[Greeter\]/a WallpaperPluginId=online.knowmad.shaderwallpaper' "$PLM"
fi
echo "  /etc/plasmalogin.conf:"; sed -n '/\[Greeter\]/,/^\[/p' "$PLM" | sed 's/^/    /'

# ── 4. plymouth ─────────────────────────────────────────────────────────
say "Installing NeonGrid boot splash"
rm -rf /usr/share/plymouth/themes/neongrid
cp -r "$REPO/boot/plymouth/neongrid" /usr/share/plymouth/themes/
plymouth-set-default-theme -R neongrid
echo "  active theme: $(plymouth-set-default-theme)"

# ── 5. limine boot menu ─────────────────────────────────────────────────
# RISK: a malformed limine.conf makes the machine unbootable. So: back it up,
# only touch global styling keys (limine-entry-tool owns the *entries*, not the
# globals), and verify entries survive before we're done.
say "Styling the Limine boot menu"
LC=/boot/limine.conf
if [ ! -f "$LC" ]; then
  echo "  !! /boot/limine.conf not found — skipping bootloader theming"
else
  cp -a "$LC" "$LC.neongrid-backup"
  cp -a "$LC" "$REPO/backup/limine.conf.orig"
  ENTRIES_BEFORE=$(grep -c "^/" "$LC" || true)

  # strip any previous NeonGrid block, then prepend a fresh one
  sed -i '/^# >>> NEONGRID/,/^# <<< NEONGRID/d' "$LC"
  TMP=$(mktemp)
  cat > "$TMP" <<EOF
# >>> NEONGRID
timeout: 3
term_background: 00${BG}
term_foreground: ${GREEN_HERO}
term_background_bright: ${SURFACE}
term_foreground_bright: ${WHITE_BR}
term_palette: ${SURFACE};${RED};${GREEN};${YELLOW};${VIOLET};${MAGENTA};${CYAN};${WHITE}
term_palette_bright: ${BLACK_BR};${RED_BR};${GREEN_HERO};${YELLOW_BR};${VIOLET_BR};${MAGENTA_BR};${CYAN_BR};${WHITE_BR}
interface_branding_colour: ${VIOLET}
interface_branding: // N E O N G R I D
interface_help_colour: ${GREEN_HERO}
term_margin: 48
# <<< NEONGRID
EOF
  cat "$LC" >> "$TMP"
  mv "$TMP" "$LC"
  chmod 644 "$LC"

  ENTRIES_AFTER=$(grep -c "^/" "$LC" || true)
  if [ "$ENTRIES_BEFORE" != "$ENTRIES_AFTER" ]; then
    echo "  !! boot entries changed ($ENTRIES_BEFORE -> $ENTRIES_AFTER) — RESTORING backup"
    cp -a "$LC.neongrid-backup" "$LC"
    exit 1
  fi
  echo "  boot entries intact ($ENTRIES_AFTER). Backup: $LC.neongrid-backup"

  # If config-checksum enrollment is in use, an edited config will refuse to boot
  # until it is re-enrolled.
  if command -v limine-enroll-config >/dev/null 2>&1; then
    limine-enroll-config 2>/dev/null && echo "  re-enrolled limine config" \
      || echo "  (enrollment not active — nothing to re-enroll)"
  fi
fi

say "Root phase complete."
