#!/usr/bin/env bash
# Derives the NeonGrid Light Global Theme from the dark one.
#
# The two packages are identical apart from which colour scheme they select, so
# the light variant is GENERATED rather than maintained by hand — otherwise the
# lock screen QML would have to be kept in sync in two places and would quietly
# drift. Dark is the source of truth; edit
# look-and-feel/com.cromewar.neongrid.dark/ and re-run this.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

DARK="$REPO/look-and-feel/com.cromewar.neongrid.dark"
LIGHT="$REPO/look-and-feel/com.cromewar.neongrid.light"

[ -d "$DARK" ] || { echo "ERROR: missing $DARK" >&2; exit 1; }

rm -rf "$LIGHT"
cp -a "$DARK" "$LIGHT"

# Only the colour scheme differs. Everything else — icons, Plasma style, cursor,
# decoration, widget style — is shared, because NeonGrid's icon set and dock
# indicators are built to read on either background.
sed -i 's|^ColorScheme=NeonGridDark$|ColorScheme=NeonGridLight|' "$LIGHT/contents/defaults"
grep -q '^ColorScheme=NeonGridLight$' "$LIGHT/contents/defaults" \
  || { echo "ERROR: colour scheme not switched — did defaults change shape?" >&2; exit 1; }

python3 - "$LIGHT/metadata.json" <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
k = m["KPlugin"]
k["Id"] = "com.cromewar.neongrid.light"
k["Name"] = "NeonGrid Light"
k["Description"] = ("NeonGrid on a light ground — same neon accents, darkened "
                    "until they clear WCAG on white")
# Fall back to Breeze LIGHT so anything this package does not provide resolves
# against a light base rather than a dark one.
m["X-KDE-fallbackPackage"] = "org.kde.breeze.desktop"
json.dump(m, open(p, "w"), indent=4, ensure_ascii=False)
open(p, "a").write("\n")
PY

echo "  built Global Theme: $LIGHT"
