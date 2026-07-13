#!/usr/bin/env bash
# NEONGRID — idempotent installer.
#
#   ./install.sh              # everything user-level
#   ./install.sh --only kde   # kde | gtk | ghostty | shell | panel | cursor | boot
#   ./install.sh --root       # the privileged pass (pkexec; cursor, greeter, boot)
#
# Root is needed for exactly four things: the cursor in /usr/share/icons, the
# shader wallpaper plugin in /usr (required for the login greeter), the Plymouth
# splash, and the Limine menu. Everything else is user-level.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

ONLY="${2:-}"
run() { [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; }
say() { printf '\n\033[1;92m▶ %s\033[0m\n' "$1"; }

if [ "${1:-}" = "--root" ]; then
  exec pkexec bash "$HERE/install-root.sh" "$USER"
fi

# ── packages ────────────────────────────────────────────────────────────
if run pkgs && [ -z "$ONLY" ]; then
  say "Packages"
  pkexec pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd inter-font starship vivid cava \
    adw-gtk-theme xdg-desktop-portal-gtk kde-gtk-config imagemagick nodejs npm
  paru --sudo pkexec --sudoflags '' --nosudoloop -S --needed --noconfirm \
    ttf-rajdhani ttf-orbitron beautyline colloid-icon-theme-git darkly-bin \
    python-clickgen klassy-git kwin-effects-better-blur-dx \
    plasma6-applets-panel-colorizer
fi

# ── KDE ─────────────────────────────────────────────────────────────────
if run kde; then
  say "KDE core (color scheme, Darkly, Klassy, fonts, icons)"
  bash kde/apply.sh
  bash kde/apply-klassy.sh
  say "Blur / glow (Better Blur DX)"
  bash kde/apply-effects.sh
fi

# ── cursor ──────────────────────────────────────────────────────────────
if run cursor; then
  say "Cursor"
  [ -d cursor/Bibata-Neon ] || bash cursor/build-bibata.sh
  kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Bibata-Neon
  kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24
  echo "  (install to /usr with: ./install.sh --root)"
fi

# ── GTK ─────────────────────────────────────────────────────────────────
if run gtk; then
  say "GTK3 / GTK4"
  bash gtk/gen-gtk.sh
fi

# ── Ghostty ─────────────────────────────────────────────────────────────
if run ghostty; then
  say "Ghostty"
  bash ghostty/gen-theme.sh
  bash ghostty/gen-shader.sh
  mkdir -p ~/.config/ghostty
  ln -sfn "$HERE/ghostty/config.ghostty" ~/.config/ghostty/config.ghostty
  ln -sfn "$HERE/ghostty/themes"  ~/.config/ghostty/themes
  ln -sfn "$HERE/ghostty/shaders" ~/.config/ghostty/shaders
  ghostty +validate-config >/dev/null && echo "  config valid"
fi

# ── shell ───────────────────────────────────────────────────────────────
if run shell; then
  say "Shell (starship, btop, fastfetch, fzf, bat, cava)"
  bash shell/gen-shell.sh
  grep -q NEONGRID ~/.zshrc 2>/dev/null || {
    printf '\n# ---------------- NEONGRID ----------------\nsource %s/shell/neongrid-env.sh\neval "$(starship init zsh)"\n' "$HERE" >> ~/.zshrc
  }
fi

# ── panel ───────────────────────────────────────────────────────────────
if run panel; then
  say "Neon panel (Panel Colorizer)"
  if ! grep -q "luisbocanegra.panel.colorizer" ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
      'var ps=panels(); if (ps.length) ps[0].addWidget("luisbocanegra.panel.colorizer");'
    sleep 2
  fi
  python3 kde/apply-panel.py
fi

# ── boot art (build only; installed by --root) ──────────────────────────
if run boot; then
  say "Boot splash art"
  bash boot/gen-plymouth.sh >/dev/null 2>&1
  echo "  built; install with: ./install.sh --root"
fi

# ── maintenance hook ────────────────────────────────────────────────────
if [ -z "$ONLY" ]; then
  say "Maintenance hook"
  pkexec install -Dm644 "$HERE/hooks/95-neongrid-rebuild.hook" \
    /etc/pacman.d/hooks/95-neongrid-rebuild.hook
fi

say "Reloading"
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
systemctl --user restart plasma-plasmashell.service 2>/dev/null || true

cat <<'EOF'

NeonGrid applied.

  Log out and back in — Klassy reads its config only at KWin start, so the neon
  window outline and green glow shadow will not appear until you do.

EOF
