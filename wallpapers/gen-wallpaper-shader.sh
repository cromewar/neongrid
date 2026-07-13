#!/usr/bin/env bash
# Forks the stock Grid_Landscape shader into the repo and recolors it to the
# NeonGrid palette: hero-green wireframe over a deep violet field.
#
# Two things learned the hard way:
#  - Many bundled shaders (Digital_Rain, Circuits, Sunset_Cyber) declare
#    iChannel0/1/2 textures the plugin never feeds them. They compile fine and
#    render PURE BLACK. Only pick self-contained shaders.
#  - The field is deliberately dark: this sits behind terminals all day.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

SRC=/usr/share/plasma/wallpapers/online.knowmad.shaderwallpaper/contents/ui/Shaders/Grid_Landscape.frag
OUT="$HERE/neongrid.frag"

# hex -> "r, g, b" GLSL floats
glsl() {
  awk -v r="$((16#${1:0:2}))" -v g="$((16#${1:2:2}))" -v b="$((16#${1:4:2}))" -v s="${2:-1.0}" \
    'BEGIN { printf "%.3f, %.3f, %.3f", r/255*s, g/255*s, b/255*s }'
}

# Grid lines are dimmed to ~45%: at full hero-green this reads as a blinding
# Tron floor and fights every window sitting on top of it. The wallpaper is
# background, not the subject.
LINES="$(glsl "$GREEN" 0.45)"
FIELD="$(glsl "$SEL_BG" 0.30)"

sed -E \
  -e "s|^#define GRID_COLOR_1 .*|#define GRID_COLOR_1 vec3($FIELD) // neongrid: deep violet field|" \
  -e "s|^#define GRID_COLOR_2 .*|#define GRID_COLOR_2 vec3($LINES) // neongrid: hero green wireframe|" \
  "$SRC" > "$OUT"

grep -q "neongrid: hero green" "$OUT" || { echo "ERROR: shader defines not patched" >&2; exit 1; }
echo "wrote $OUT"
grep -E "^#define GRID_COLOR" "$OUT"
