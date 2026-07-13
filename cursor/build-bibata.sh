#!/usr/bin/env bash
# Builds a neon-green Bibata cursor from upstream SVGs.
#
# Upstream's own README documents this exact route (it calls its green build
# "Bibata-Hacker"). bibata.live is a paid GUI for the same thing — the free
# cbmp + ctgen CLI does the identical job, so we use that.
#
# cbmp swaps placeholder colors in the SVGs:
#   -bc replaces #00FF00 (base fill)   -> our hero green
#   -oc replaces #0000FF (outline)     -> violet
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

NAME="Bibata-Neon"
WORK="$HERE/.build"
OUT="$HERE/$NAME"

command -v ctgen >/dev/null || { echo "ctgen missing — install python-clickgen" >&2; exit 1; }
command -v npx   >/dev/null || { echo "npx missing — install nodejs/npm" >&2; exit 1; }

rm -rf "$WORK" "$OUT"
mkdir -p "$WORK"
git clone --depth 1 https://github.com/ful1e5/Bibata_Cursor.git "$WORK/src" 2>/dev/null

cd "$WORK/src"
npx --yes cbmp -d 'svg/modern' -o "bitmaps/$NAME" -bc "$(hx "$GREEN_HERO")" -oc "$(hx "$CURSOR_OUTLINE")"

# Upstream drives ctgen from configs/normal/x.build.toml (that file carries the
# hotspots and the size list) — there is no build.toml at the repo root.
ctgen configs/normal/x.build.toml -p x11 \
  -d "bitmaps/$NAME" -n "$NAME" -c "NeonGrid neon-green Bibata"

cp -r "themes/$NAME" "$OUT"
echo "built: $OUT"
echo "install with: sudo cp -r '$OUT' /usr/share/icons/"
echo "  (/usr, NOT ~/.local/share/icons — some Wayland/GTK clients cannot see cursors in the user dir)"
