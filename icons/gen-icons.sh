#!/usr/bin/env bash
# Builds the NeonGrid icon OVERLAY theme.
#
# The problem: every icon theme keeps each app's brand hue — Brave orange,
# Firefox orange, Claude coral, Obsidian violet. On a dock that reads as a
# rainbow and fights the theme.
#
# The fix is NOT to flatten everything to one color (that looks sterile and
# kills the neon). Each app gets its OWN two-stop gradient, drawn from the
# NeonGrid palette. Variety stays; the palette stays coherent.
#
# Source SVGs: simple-icons / lobe-icons. Every one of these apps ships only a
# PNG, so the upstream vector brand marks are the correct source.
# The theme INHERITS BeautyLine, so icons we don't override still resolve.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

THEME="$HOME/.local/share/icons/NeonGrid"
SI="https://raw.githubusercontent.com/simple-icons/simple-icons/master/icons"
LOBE="https://raw.githubusercontent.com/lobehub/lobe-icons/master/packages/static-svg/icons"

OUT="$THEME/apps/scalable"
mkdir -p "$OUT"

# icon-name (the .desktop Icon= key) | source URL | gradient start | gradient end
# Gradients run along the icon diagonal. Each app is distinct, all are neon.
MAP="
com.mitchellh.ghostty|$SI/ghostty.svg|$GREEN_HERO|$CYAN
openai-codex-desktop|$LOBE/openai.svg|$CYAN_BR|$GREEN
claude-desktop|$SI/claude.svg|$GREEN_HERO|$YELLOW
antigravity-ide|$LOBE/antigravity.svg|$CYAN|$VIOLET
brave-desktop|$SI/brave.svg|$VIOLET|$RED
firefox|$SI/firefoxbrowser.svg|$MAGENTA|$RED_BR
obsidian|$SI/obsidian.svg|$VIOLET|$MAGENTA_BR
ticktick|$SI/ticktick.svg|$GREEN|$CYAN_BR
"

# Injects a linearGradient into a flat single-path brand mark.
grad_svg() {
  python3 - "$1" "$2" "#$3" "#$4" <<'PY'
import re, sys
src, dst, c1, c2 = sys.argv[1:5]
s = open(src).read()
s = re.sub(r'\sfill="(?!none)[^"]*"', '', s)   # drop the baked-in brand fill
gid = "ngGrad"
defs = (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="{c1}"/>'
        f'<stop offset="1" stop-color="{c2}"/></linearGradient></defs>')
s = re.sub(r'(<svg\b[^>]*>)', r'\1' + defs, s, count=1)
s = re.sub(r'<svg\b', f'<svg fill="url(#{gid})"', s, count=1)
open(dst, 'w').write(s)
PY
}

while IFS='|' read -r name url c1 c2; do
  [ -n "$name" ] || continue
  tmp=$(mktemp)
  if ! curl -fsSL "$url" -o "$tmp"; then
    echo "  !! could not fetch $name" >&2; rm -f "$tmp"; continue
  fi
  grad_svg "$tmp" "$OUT/$name.svg" "$c1" "$c2"
  rm -f "$tmp"
  echo "  $name  #$c1 -> #$c2"
done <<< "$MAP"

# --- Antigravity vs Antigravity IDE -----------------------------------------
# Upstream ships the SAME arch glyph for both; the only difference is that the
# launcher sits on a rounded tile and the IDE is bare. Identical icons side by
# side in a dock are useless, so we make that distinction explicit AND give them
# different gradients:
#   antigravity      -> arch inside a neon tile frame, green->cyan
#   antigravity-ide  -> bare arch, cyan->violet (written by the MAP above)
ARCH='M21.751 22.607c1.34 1.005 3.35.335 1.508-1.508C17.73 15.74 18.904 1 12.037 1 5.17 1 6.342 15.74.815 21.1c-2.01 2.009.167 2.511 1.507 1.506 5.192-3.517 4.857-9.714 9.715-9.714 4.857 0 4.522 6.197 9.714 9.715z'
cat > "$OUT/antigravity.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill-rule="evenodd">
  <title>Antigravity</title>
  <defs>
    <linearGradient id="agFill" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="$(hx "$GREEN_HERO")"/>
      <stop offset="1" stop-color="$(hx "$CYAN")"/>
    </linearGradient>
  </defs>
  <rect x="0.9" y="0.9" width="22.2" height="22.2" rx="5.2"
        fill="none" stroke="url(#agFill)" stroke-width="1.5" opacity="0.85"/>
  <g transform="translate(12 12.4) scale(0.62) translate(-12 -12)">
    <path d="$ARCH" fill="url(#agFill)"/>
  </g>
</svg>
EOF
echo "  antigravity  #$GREEN_HERO -> #$CYAN (tiled, to distinguish from the IDE)"

# --- stragglers -------------------------------------------------------------
# File manager + launcher come from BeautyLine, which paints the folder bright
# orange. BeautyLine already uses linearGradients, so we only need to rewrite
# its stop-colors — that PRESERVES the gradient and just moves it into palette.
recolor_local() {
  local src="$1" name="$2" c1="$3" c2="$4"
  [ -f "$src" ] || return 0
  python3 - "$src" "$OUT/$name.svg" "#$c1" "#$c2" <<'PY'
import re, sys
src, dst, c1, c2 = sys.argv[1:5]
s = open(src).read()
stops = [c1, c2]; i = [0]
def nxt(_m):
    c = stops[i[0] % 2]; i[0] += 1
    return f'stop-color="{c}"'
s = re.sub(r'stop-color="[^"]*"', nxt, s)
s = re.sub(r'stop-color:\s*[^;"\']+', lambda m: f'stop-color:{c1}', s)
s = re.sub(r'fill:\s*#[0-9a-fA-F]{3,6}', f'fill:{c1}', s)
s = re.sub(r'stroke:\s*#[0-9a-fA-F]{3,6}', f'stroke:{c1}', s)
s = re.sub(r'fill="(?!none|url)[^"]*"', f'fill="{c1}"', s)
s = re.sub(r'stroke="(?!none|url)#[0-9a-fA-F]{3,6}"', f'stroke="{c1}"', s)
open(dst, 'w').write(s)
PY
  echo "  $name  #$c1 -> #$c2 (BeautyLine gradient remapped)"
}

BL=/usr/share/icons/BeautyLine/apps/scalable
recolor_local "$BL/system-file-manager.svg" system-file-manager "$GREEN_HERO" "$CYAN"
recolor_local "$BL/org.kde.dolphin.svg"     org.kde.dolphin     "$GREEN_HERO" "$CYAN"
recolor_local "$BL/start-here.svg"          start-here          "$VIOLET"     "$GREEN_HERO"
recolor_local "$BL/start-here-kde.svg"      start-here-kde      "$VIOLET"     "$GREEN_HERO"
recolor_local "$BL/start-here.svg"          org.cachyos.hello   "$VIOLET"     "$GREEN_HERO"

# hue-snap.py builds the full theme (copied from BeautyLine, every hue snapped
# into the palette) and brings a complete index.theme with it. Only write a
# standalone index if that hasn't run — otherwise we'd throw away every
# directory mapping and the theme would resolve almost nothing.
if [ ! -f "$THEME/index.theme" ]; then
cat > "$THEME/index.theme" <<EOF
[Icon Theme]
Name=NeonGrid
Comment=Neon gradient app marks over BeautyLine
Inherits=BeautyLine,Colloid-Dark,breeze-dark,hicolor
Directories=apps/scalable

[apps/scalable]
Size=48
MinSize=16
MaxSize=512
Context=Applications
Type=Scalable
EOF
fi

gtk-update-icon-cache -f -t "$THEME" 2>/dev/null || true
echo "built: $THEME"
