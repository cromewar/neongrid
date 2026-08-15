#!/usr/bin/env bash
# Point every desktop at the NeonGrid GLSL wallpaper.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
FRAG="$REPO/wallpapers/neongrid.frag"
[ -f "$FRAG" ] || { echo "  !! missing $FRAG" >&2; exit 1; }

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
  var d = desktops();
  for (var i = 0; i < d.length; i++) {
    d[i].wallpaperPlugin = 'online.knowmad.shaderwallpaper';
    d[i].currentConfigGroup = ['Wallpaper','online.knowmad.shaderwallpaper','General'];
    d[i].writeConfig('selectedShaderPath', '$FRAG');
    d[i].writeConfig('running', true);
    d[i].writeConfig('targetFps', 30);
    d[i].writeConfig('resolutionScale', 0.75);
    d[i].writeConfig('pauseMode', 0);
    d[i].writeConfig('shaderSpeed', 0.6);
    d[i].writeConfig('audioEnabled', false);
    d[i].reloadConfig();
  }" >/dev/null 2>&1
echo "  shader wallpaper -> $FRAG"
