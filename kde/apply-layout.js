// NeonGrid panel layout — the reference machine:
//   top bar   34px, always visible, applets-float
//   bottom dock 64px, floating, fit-content, dodge windows
//
// Placeholders (substituted by apply-layout.sh):
//   __LAUNCHERS__   comma-separated icontasks launchers that exist here
//   __HAS_POMODORO__  "1" or "0"
//   __HAS_DOWNLOADS__ "1" or "0"

var LAUNCHERS = "__LAUNCHERS__";
var HAS_POMODORO = "__HAS_POMODORO__" === "1";
var HAS_DOWNLOADS = "__HAS_DOWNLOADS__" === "1";

function findPanel(location) {
    var ps = panels();
    for (var i = 0; i < ps.length; i++) {
        if (ps[i].location === location) return ps[i];
    }
    return null;
}

function hasWidget(panel, type) {
    var w = panel.widgets();
    for (var i = 0; i < w.length; i++) {
        if (w[i].type === type) return w[i];
    }
    return null;
}

function ensureWidget(panel, type) {
    var existing = hasWidget(panel, type);
    if (existing) return existing;
    try {
        return panel.addWidget(type);
    } catch (e) {
        print("NeonGrid: could not add " + type + ": " + e);
        return null;
    }
}

function removeType(panel, type) {
    if (!panel) return;
    var w = hasWidget(panel, type);
    if (w) {
        try { w.remove(); } catch (e) {}
    }
}

function getOrCreate(location) {
    var p = findPanel(location);
    if (p) return p;
    p = new Panel;
    p.location = location;
    return p;
}

var bottom = findPanel("bottom");
var top = findPanel("top");

// Fresh CachyOS: one kitchen-sink bottom panel. Strip the status widgets
// off it; the top-bar block below adds them in the reference order.
if (bottom && !top && hasWidget(bottom, "org.kde.plasma.systemtray")) {
    removeType(bottom, "org.kde.plasma.pager");
    removeType(bottom, "org.kde.plasma.marginsseparator");
    removeType(bottom, "org.kde.plasma.systemtray");
    removeType(bottom, "org.kde.plasma.digitalclock");
    removeType(bottom, "org.kde.plasma.showdesktop");
}

if (!bottom) bottom = getOrCreate("bottom");
if (!top) top = getOrCreate("top");

// --- bottom dock -------------------------------------------------------
bottom.location = "bottom";
bottom.height = 64;
try { bottom.hiding = "dodgewindows"; } catch (e) { try { bottom.hiding = "windowscover"; } catch (e2) {} }
try { bottom.lengthMode = "fit"; } catch (e) { try { bottom.lengthMode = "fitContent"; } catch (e2) {} }
bottom.floating = true;
bottom.alignment = "center";

ensureWidget(bottom, "org.kde.plasma.kickoff");
var tasks = ensureWidget(bottom, "org.kde.plasma.icontasks");
ensureWidget(bottom, "luisbocanegra.panel.colorizer");
if (HAS_DOWNLOADS) {
    var stack = ensureWidget(bottom, "com.cromewar.downloadsstack");
    if (stack) {
        stack.currentConfigGroup = ["Appearance"];
        stack.writeConfig("iconSize", 56);
    }
}

var kickoff = hasWidget(bottom, "org.kde.plasma.kickoff");
if (kickoff) {
    kickoff.currentConfigGroup = ["General"];
    kickoff.writeConfig("icon", "org.cachyos.hello");
}

if (tasks && LAUNCHERS.length) {
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", LAUNCHERS);
    tasks.writeConfig("unhideOnAttention", false);
}

// --- top bar -----------------------------------------------------------
top.location = "top";
top.height = 34;
top.hiding = "normal";
top.lengthMode = "fill";
top.floating = false;
try { top.floatingApplets = true; } catch (e) {}

ensureWidget(top, "org.kde.plasma.pager");
ensureWidget(top, "org.kde.plasma.marginsseparator");
if (HAS_POMODORO) ensureWidget(top, "org.kde.plasma.pomodoro");
ensureWidget(top, "org.kde.plasma.panelspacer");
ensureWidget(top, "org.kde.plasma.systemtray");
var clock = ensureWidget(top, "org.kde.plasma.digitalclock");
ensureWidget(top, "org.kde.plasma.showdesktop");
ensureWidget(top, "luisbocanegra.panel.colorizer");

if (clock) {
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("autoFontAndSize", false);
    clock.writeConfig("fontFamily", "Rajdhani");
    clock.writeConfig("fontSize", 11);
    clock.writeConfig("fontWeight", 600);
    clock.writeConfig("showDate", false);
    clock.writeConfig("use24hFormat", 2);
}

print("NeonGrid: panel layout applied");
