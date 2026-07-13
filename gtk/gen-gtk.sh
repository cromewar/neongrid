#!/usr/bin/env bash
# GTK3 + GTK4/libadwaita.
#
# Two things to know:
#  - Gradience is ARCHIVED. Do not reach for it. Hand-written CSS is the 2026 way.
#  - libadwaita has no theme API: a GTK theme cannot restyle it. What DOES work is
#    (a) KDE's accent-color portal, which libadwaita 1.6+ reads, so the neon accent
#        arrives for free, and (b) @define-color overrides for the rest.
#  - GTK apps never request blur; theirs comes from Better Blur DX force-blur.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0

# --- GTK3 settings ------------------------------------------------------
cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=NeonGrid
gtk-cursor-theme-name=Bibata-Neon
gtk-cursor-theme-size=24
gtk-font-name=Rajdhani 11
gtk-application-prefer-dark-theme=true
gtk-enable-animations=true
gtk-decoration-layout=icon:minimize,maximize,close
gtk-modules=colorreload-gtk-module:window-decorations-gtk-module
gtk-sound-theme-name=ocean
gtk-primary-button-warps-slider=true
EOF

# --- GTK4 settings ------------------------------------------------------
cat > ~/.config/gtk-4.0/settings.ini <<EOF
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=NeonGrid
gtk-cursor-theme-name=Bibata-Neon
gtk-cursor-theme-size=24
gtk-font-name=Rajdhani 11
gtk-application-prefer-dark-theme=true
EOF

# --- libadwaita recolor -------------------------------------------------
gtk4_css() {
cat <<EOF
/* NeonGrid — generated from cyberdeck/palette.sh. Do not hand-edit. */
@define-color accent_color $(hx "$GREEN_HERO");
@define-color accent_bg_color $(hx "$GREEN");
@define-color accent_fg_color $(hx "$BG");

@define-color window_bg_color $(hx "$SURFACE");
@define-color window_fg_color $(hx "$FG");
@define-color view_bg_color $(hx "$BG");
@define-color view_fg_color $(hx "$FG");
@define-color headerbar_bg_color $(hx "$SURFACE");
@define-color headerbar_fg_color $(hx "$FG");
@define-color headerbar_border_color $(hx "$GREEN_HERO");
@define-color headerbar_backdrop_color $(hx "$BG");
@define-color sidebar_bg_color $(hx "$SURFACE");
@define-color sidebar_fg_color $(hx "$FG");
@define-color sidebar_backdrop_color $(hx "$BG");
@define-color secondary_sidebar_bg_color $(hx "$BG");
@define-color card_bg_color $(hx "$SURFACE_HI");
@define-color card_fg_color $(hx "$FG");
@define-color dialog_bg_color $(hx "$SURFACE");
@define-color dialog_fg_color $(hx "$FG");
@define-color popover_bg_color $(hx "$SURFACE_HI");
@define-color popover_fg_color $(hx "$FG");
@define-color thumbnail_bg_color $(hx "$SURFACE");

@define-color destructive_color $(hx "$RED");
@define-color destructive_bg_color $(hx "$RED");
@define-color success_color $(hx "$GREEN");
@define-color success_bg_color $(hx "$GREEN");
@define-color warning_color $(hx "$YELLOW");
@define-color error_color $(hx "$RED");

/* focus rings pick up the hero neon */
:focus-visible { outline-color: $(hx "$GREEN_HERO"); }
EOF
}
gtk4_css > ~/.config/gtk-4.0/gtk.css
gtk4_css > ~/.config/gtk-3.0/gtk.css

echo "GTK applied."
