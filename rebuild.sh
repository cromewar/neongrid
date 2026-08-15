#!/usr/bin/env bash
# Rebuild the three compiled components after a Plasma/KWin upgrade.
# Run this whenever the pacman hook warns you (or if blur/decorations vanish).
set -euo pipefail

echo "Rebuilding NeonGrid's compiled components against the current Plasma…"
paru -S --rebuild --noconfirm \
  kwin-effects-better-blur-dx \
  klassy-git \
  plasma6-applets-panel-colorizer

echo
echo "Re-applying effect config and restarting the shell…"
bash "$(dirname "$0")/kde/apply-effects.sh"
# The Plasma style is derived FROM the installed Breeze tasks.svg, so a
# plasma-workspace upgrade can move the frame ids out from under it.
bash "$(dirname "$0")/kde/apply-desktoptheme.sh"
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
systemctl --user restart plasma-plasmashell.service

cat <<'EOF'

Done. If plasmashell is now crash-looping, the Panel Colorizer C++ plugin is the
usual culprit. Recover with:

    rm -rf ~/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer
    systemctl --user restart plasma-plasmashell.service

then reinstall the widget and re-run:  python3 ~/cyberdeck/kde/apply-panel.py
EOF
