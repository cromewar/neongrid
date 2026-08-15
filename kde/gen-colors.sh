#!/usr/bin/env bash
# Generates the KDE color scheme(s) from palette.sh.
# Darkly + Kirigami + kde-gtk-config all read this, so it is what makes the
# neon accent reach every Qt app, System Settings, and GTK3 without extra work.
#
#   gen-colors.sh [outfile]            -> NeonGrid.colors      (dark)
#   gen-colors.sh --light [outfile]    -> NeonGridLight.colors (light)
#
# Both variants run through the SAME emitter below; only the palette bindings
# differ, so the two schemes can never drift apart in structure.
set -euo pipefail
source "$(dirname "$0")/../palette.sh"

MODE="dark"
OUT=""
for a in "$@"; do
  case "$a" in
    --light) MODE="light" ;;
    --dark)  MODE="dark" ;;
    *)       OUT="$a" ;;
  esac
done

if [ "$MODE" = "light" ]; then
  neongrid_light
  SCHEME="NeonGridLight"
  DISPLAY="NeonGrid Light"
else
  SCHEME="NeonGrid"
  DISPLAY="NeonGrid"
fi

OUT="${OUT:-$(dirname "$0")/$SCHEME.colors}"

cat > "$OUT" <<EOF
[General]
ColorScheme=$SCHEME
Name=$DISPLAY
accent=$(rgb "$ACCENT")
shadeSortColumn=true

[ColorEffects:Disabled]
Color=$(rgb "$SURFACE")
ColorAmount=0
ColorEffect=0
ContrastAmount=0.4
ContrastEffect=1
IntensityAmount=0
IntensityEffect=0

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=$(rgb "$SURFACE")
ColorAmount=0.05
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=0
Enable=true
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=$(rgb "$SURFACE_HI")
BackgroundNormal=$(rgb "$SURFACE")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT_ALT")
ForegroundActive=$(rgb "$ACCENT")
ForegroundInactive=$(rgb "$FG_DIM")
ForegroundLink=$(rgb "$VIOLET")
ForegroundNegative=$(rgb "$RED")
ForegroundNeutral=$(rgb "$YELLOW")
ForegroundNormal=$(rgb "$FG")
ForegroundPositive=$(rgb "$GREEN")
ForegroundVisited=$(rgb "$MAGENTA")

[Colors:Complementary]
BackgroundAlternate=$(rgb "$SURFACE_HI")
BackgroundNormal=$(rgb "$BG")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT_ALT")
ForegroundActive=$(rgb "$ACCENT")
ForegroundInactive=$(rgb "$FG_DIM")
ForegroundLink=$(rgb "$VIOLET")
ForegroundNegative=$(rgb "$RED")
ForegroundNeutral=$(rgb "$YELLOW")
ForegroundNormal=$(rgb "$FG")
ForegroundPositive=$(rgb "$GREEN")
ForegroundVisited=$(rgb "$MAGENTA")

[Colors:Header]
BackgroundAlternate=$(rgb "$SURFACE")
BackgroundNormal=$(rgb "$SURFACE")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT_ALT")
ForegroundActive=$(rgb "$ACCENT")
ForegroundInactive=$(rgb "$FG_DIM")
ForegroundLink=$(rgb "$VIOLET")
ForegroundNegative=$(rgb "$RED")
ForegroundNeutral=$(rgb "$YELLOW")
ForegroundNormal=$(rgb "$FG")
ForegroundPositive=$(rgb "$GREEN")
ForegroundVisited=$(rgb "$MAGENTA")

[Colors:Header][Inactive]
BackgroundAlternate=$(rgb "$SURFACE")
BackgroundNormal=$(rgb "$BG")
ForegroundNormal=$(rgb "$FG_DIM")

[Colors:Selection]
BackgroundAlternate=$(rgb "$SEL_BG")
BackgroundNormal=$(rgb "$SEL_BG")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT_ALT")
ForegroundActive=$(rgb "$ACCENT")
ForegroundInactive=$(rgb "$FG_DIM")
ForegroundLink=$(rgb "$VIOLET_BR")
ForegroundNegative=$(rgb "$RED")
ForegroundNeutral=$(rgb "$YELLOW")
ForegroundNormal=$(rgb "$SEL_FG")
ForegroundPositive=$(rgb "$GREEN")
ForegroundVisited=$(rgb "$MAGENTA")

[Colors:Tooltip]
BackgroundAlternate=$(rgb "$SURFACE_HI")
BackgroundNormal=$(rgb "$SURFACE")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT_ALT")
ForegroundActive=$(rgb "$ACCENT")
ForegroundInactive=$(rgb "$FG_DIM")
ForegroundLink=$(rgb "$VIOLET")
ForegroundNegative=$(rgb "$RED")
ForegroundNeutral=$(rgb "$YELLOW")
ForegroundNormal=$(rgb "$FG")
ForegroundPositive=$(rgb "$GREEN")
ForegroundVisited=$(rgb "$MAGENTA")

[Colors:View]
BackgroundAlternate=$(rgb "$SURFACE")
BackgroundNormal=$(rgb "$BG")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT_ALT")
ForegroundActive=$(rgb "$ACCENT")
ForegroundInactive=$(rgb "$FG_DIM")
ForegroundLink=$(rgb "$VIOLET")
ForegroundNegative=$(rgb "$RED")
ForegroundNeutral=$(rgb "$YELLOW")
ForegroundNormal=$(rgb "$FG")
ForegroundPositive=$(rgb "$GREEN")
ForegroundVisited=$(rgb "$MAGENTA")

[Colors:Window]
BackgroundAlternate=$(rgb "$SURFACE")
BackgroundNormal=$(rgb "$SURFACE")
DecorationFocus=$(rgb "$ACCENT")
DecorationHover=$(rgb "$ACCENT_ALT")
ForegroundActive=$(rgb "$ACCENT")
ForegroundInactive=$(rgb "$FG_DIM")
ForegroundLink=$(rgb "$VIOLET")
ForegroundNegative=$(rgb "$RED")
ForegroundNeutral=$(rgb "$YELLOW")
ForegroundNormal=$(rgb "$FG")
ForegroundPositive=$(rgb "$GREEN")
ForegroundVisited=$(rgb "$MAGENTA")

[WM]
activeBackground=$(rgb "$SURFACE")
activeBlend=$(rgb "$ACCENT")
activeForeground=$(rgb "$WHITE_BR")
inactiveBackground=$(rgb "$BG")
inactiveBlend=$(rgb "$SURFACE")
inactiveForeground=$(rgb "$FG_DIM")
EOF

echo "wrote $OUT"
