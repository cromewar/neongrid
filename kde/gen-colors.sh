#!/usr/bin/env bash
# Generates NeonGrid.colors (KDE color scheme) from palette.sh.
# Darkly + Kirigami + kde-gtk-config all read this, so it is what makes the
# neon accent reach every Qt app, System Settings, and GTK3 without extra work.
set -euo pipefail
source "$(dirname "$0")/../palette.sh"

OUT="${1:-$(dirname "$0")/NeonGrid.colors}"

cat > "$OUT" <<EOF
[General]
ColorScheme=NeonGrid
Name=NeonGrid
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
