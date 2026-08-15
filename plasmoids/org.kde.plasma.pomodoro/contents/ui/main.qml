pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notification
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property int focusMinutes: Math.max(1, Plasmoid.configuration.focusMinutes)
    readonly property int shortBreakMinutes: Math.max(1, Plasmoid.configuration.shortBreakMinutes)
    readonly property int longBreakMinutes: Math.max(1, Plasmoid.configuration.longBreakMinutes)
    readonly property int sessionsUntilLongBreak: Math.max(1, Plasmoid.configuration.sessionsUntilLongBreak)
    readonly property string focusDescription: Plasmoid.configuration.focusDescription
    readonly property bool autoStartBreaks: Plasmoid.configuration.autoStartBreaks
    readonly property bool autoStartFocus: Plasmoid.configuration.autoStartFocus
    readonly property bool showInlineSettings: Plasmoid.configuration.showInlineSettings

    readonly property PresetTable presetTable: PresetTable {}
    readonly property var presets: presetTable.list
    // Derived, never stored — see PresetTable.matchingIndex(). Because it reads
    // the mirrored config properties above, every consumer (menu check marks,
    // the settings dialog's combo box) follows a duration change for free.
    readonly property int activePresetIndex: presetTable.matchingIndex(
        focusMinutes, shortBreakMinutes, longBreakMinutes, sessionsUntilLongBreak)

    property string phase: "focus"
    property bool isRunning: false
    property int remainingSeconds: 1500
    property int phaseTotalSeconds: 1500
    property double deadlineMs: 0
    property int focusesSinceLongBreak: 0
    property int completedFocusSessions: 0
    property int completedFocusSessionsToday: 0
    property string dailyCounterDate: ""
    // Finished days as compact ["YYYY-MM-DD", count] pairs, oldest first, capped
    // at 90. Storage only for now: nothing renders this yet. The array is sparse
    // by design — a day the widget never saw simply has no entry.
    property var dailyHistory: []
    property string pendingNotificationPhase: ""
    property bool initialized: false

    readonly property real progress: phaseTotalSeconds > 0
        ? Math.max(0, Math.min(1, 1 - remainingSeconds / phaseTotalSeconds))
        : 0
    readonly property string formattedTime: formatTime(remainingSeconds)
    readonly property string phaseName: phase === "focus"
        ? i18n("Focus")
        : (phase === "longBreak" ? i18n("Long break") : i18n("Short break"))
    // Phase colours come from the scheme's semantic status roles rather than
    // fixed hex, so the widget follows the user's palette (including
    // high-contrast schemes) instead of being the one thing in the panel that
    // ignores it.
    //
    // `positiveTextColor` and `negativeTextColor` are the only two roles every
    // scheme is *obliged* to keep mutually distinguishable — they carry
    // success/error meaning — which makes them a far safer pair than a third
    // independent root: `highlightColor` is the user's accent and can land
    // straight on top of either. So the long break is the *same* "rest" root
    // rotated a sixth of the way round the hue wheel (green -> steel blue under
    // Breeze), keeping its saturation and lightness. The two break phases can
    // then never collide whatever green the scheme chose, and all three phases
    // end up with comparable contrast against the popup background.
    readonly property color restColor: Kirigami.Theme.positiveTextColor
    readonly property color longRestColor: Qt.hsla(
        // "+ 1" first: an achromatic colour reports hslHue as -1.
        (restColor.hslHue + 1 + 1 / 6) % 1,
        restColor.hslSaturation,
        restColor.hslLightness,
        1)
    readonly property color accentColor: phase === "focus"
        ? Kirigami.Theme.negativeTextColor
        : (phase === "longBreak" ? longRestColor : restColor)
    // The scheme's designated "text drawn on a saturated background" colour.
    // This is what the literal "white" in PlaybackButton was standing in for,
    // except it stays legible when the accent is pale or the scheme is
    // high-contrast.
    readonly property color accentForegroundColor: Kirigami.Theme.highlightedTextColor
    // Deliberately derived from `deadlineMs` alone rather than `remainingSeconds`,
    // so it is recomputed once per interval instead of four times a second. There
    // is no deadline while paused, and `Date.now()` is not reactive, so a paused
    // estimate would be stale seconds after it was rendered: return nothing.
    // `toLocaleTimeString(Qt.locale(), ...)` rather than `Qt.formatTime(...)`:
    // the latter formats with the application's default QLocale, which Plasma
    // leaves at "C" (a 24-hour "HH:mm:ss"), while `Qt.locale()` is the region the
    // user actually configured and decides 12- versus 24-hour on their behalf.
    readonly property string estimatedFinishTime: isRunning && deadlineMs > 0
        ? new Date(deadlineMs).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
        : ""
    readonly property string notificationActionLabel: pendingNotificationPhase === "focus"
        ? i18n("Start focus")
        : (pendingNotificationPhase === "longBreak"
            ? i18n("Start long break")
            : i18n("Start break"))

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.icon: "chronometer"
    Plasmoid.status: isRunning ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    Plasmoid.title: i18n("Pomodoro Focus")

    toolTipMainText: focusDescription.length > 0 ? focusDescription : phaseName
    // Two lines, not five inline fields: line one is the state of the interval
    // running right now, line two is how much has been banked. Plasma's
    // DefaultToolTip caps its text column at `gridUnit * 20` and word-wraps, so
    // a fifth inline field lands within a few pixels of that cap in English and
    // wraps outright once translated — orphaning the last word onto a ragged
    // second line the layout never intended. Splitting deliberately keeps both
    // lines short, and puts the two counts side by side where they are actually
    // comparable instead of separating them with the same "·" that divides the
    // unrelated phase/time/finish fields.
    //
    // The lifetime line is dropped entirely until there is something to report.
    // Testing `completedFocusSessions` alone is sufficient: both counters are
    // incremented in the same branch of moveToNextPhase(), so today's count can
    // never run ahead of the lifetime one, and a zero total means a fresh
    // install with nothing to say rather than a counter that merely reset.
    toolTipSubText: {
        const runState = isRunning ? i18n("Ends %1", estimatedFinishTime) : i18n("Paused");
        if (completedFocusSessions <= 0) {
            return i18nc("Tooltip subtext before any focus session has ever been completed: timer phase, remaining time, and finish time while running or the paused state",
                "%1 · %2 · %3",
                phaseName,
                formattedTime,
                runState);
        }
        return i18nc("Two-line tooltip subtext. Line one: timer phase, remaining time, and finish time while running or the paused state. Line two: focus sessions completed today, then the lifetime total. Keep the line break between them.",
            "%1 · %2 · %3\n%4 today · %5 all time",
            phaseName,
            formattedTime,
            runState,
            completedFocusSessionsToday,
            completedFocusSessions);
    }
    toolTipTextFormat: Text.PlainText

    preferredRepresentation: Qt.application.name === "plasmawindowed"
        ? fullRepresentation
        : compactRepresentation
    compactRepresentation: CompactRepresentation {
        controller: root
    }
    fullRepresentation: FullRepresentation {
        controller: root
    }

    property PlasmaCore.Action toggleAction: PlasmaCore.Action {
        text: root.isRunning ? i18n("Pause") : i18n("Start")
        icon.name: root.isRunning ? "media-playback-pause" : "media-playback-start"
        onTriggered: root.toggleTimer()
    }

    property PlasmaCore.Action skipAction: PlasmaCore.Action {
        text: i18n("Skip interval")
        icon.name: "media-skip-forward"
        onTriggered: root.skipInterval()
    }

    property PlasmaCore.Action resetAction: PlasmaCore.Action {
        text: i18n("Restart interval")
        icon.name: "view-refresh"
        onTriggered: root.resetCurrentInterval()
    }

    property PlasmaCore.Action resetDailyCountAction: PlasmaCore.Action {
        text: i18n("Reset today's count")
        icon.name: "edit-reset"
        onTriggered: root.resetDailyCount()
    }

    // Switching the whole cycle is a monthly action, not a daily one, so it
    // belongs on the free surface the right-click menu already provides rather
    // than costing a permanent row in the popup.
    //
    // Flat entries with a shared prefix, not a "Presets ▸" submenu: the only
    // submenu hook `PlasmaCore.Action` has is its `menu` property, and that is
    // typed `QMenu *` — a QWidget the QML engine does not export as a creatable
    // type (corebindingsplugin.qmltypes exports `Action` and `ActionGroup`;
    // `QMenu` appears there only as an unexported prototype). The one in-tree
    // applet with a submenu, folderview, hands its action a QMenu built by a
    // C++ plugin. A pure-QML plasmoid has no equivalent.
    property PlasmaCore.Action presetSeparatorAction: PlasmaCore.Action {
        isSeparator: true
    }

    property PlasmaCore.Action classicPresetAction: PlasmaCore.Action {
        id: classicPreset

        text: root.presetActionText(0)
        checkable: true
        checked: root.activePresetIndex === 0
        // Re-triggering the already-checked entry makes QAction toggle `checked`
        // off on its way to emitting triggered(). The durations do not change,
        // so `activePresetIndex` never re-emits and the binding is never
        // re-evaluated to put the mark back — restore it explicitly.
        //
        // Through the id, never a bare `checked = ...`: an unqualified
        // assignment in a handler is a plain JavaScript assignment that invents
        // a variable instead of writing the property, so the mark silently
        // stays off. Unqualified *reads* resolve through the scope chain and
        // hide this.
        onTriggered: {
            root.applyPreset(0);
            classicPreset.checked = Qt.binding(() => root.activePresetIndex === 0);
        }
    }

    property PlasmaCore.Action deepWorkPresetAction: PlasmaCore.Action {
        id: deepWorkPreset

        text: root.presetActionText(1)
        checkable: true
        checked: root.activePresetIndex === 1
        onTriggered: {
            root.applyPreset(1);
            deepWorkPreset.checked = Qt.binding(() => root.activePresetIndex === 1);
        }
    }

    property PlasmaCore.Action longHaulPresetAction: PlasmaCore.Action {
        id: longHaulPreset

        text: root.presetActionText(2)
        checkable: true
        checked: root.activePresetIndex === 2
        onTriggered: {
            root.applyPreset(2);
            longHaulPreset.checked = Qt.binding(() => root.activePresetIndex === 2);
        }
    }

    Plasmoid.contextualActions: [
        toggleAction,
        skipAction,
        resetAction,
        resetDailyCountAction,
        presetSeparatorAction,
        classicPresetAction,
        deepWorkPresetAction,
        longHaulPresetAction
    ]

    // The three durations are spelled out because a preset name alone ("Deep
    // work") says nothing about what it is going to do to the timer, and the
    // menu is the only place these entries are ever seen.
    function presetActionText(index) {
        const preset = presets[index];
        return i18nc("@action:inmenu %1 is a preset name, %2/%3/%4 are focus, short break and long break minutes",
            "Preset: %1 (%2/%3/%4 min)",
            preset.name,
            preset.focusMinutes,
            preset.shortBreakMinutes,
            preset.longBreakMinutes);
    }

    function applyPreset(index) {
        if (index < 0 || index >= presets.length) {
            return;
        }
        const preset = presets[index];

        Plasmoid.configuration.focusMinutes = preset.focusMinutes;
        Plasmoid.configuration.shortBreakMinutes = preset.shortBreakMinutes;
        Plasmoid.configuration.longBreakMinutes = preset.longBreakMinutes;
        Plasmoid.configuration.sessionsUntilLongBreak = preset.sessionsUntilLongBreak;
        // One flush for the whole preset. The per-setting setters below each
        // call writeConfig() themselves, so routing through them would hit the
        // config file four times for a single menu click.
        Plasmoid.configuration.writeConfig();

        // A preset can shrink the cycle (4 focuses -> 2). With three already
        // banked, the popup's pips would render every dot saturated and the
        // very next focus would hand out a long break. `focusesSinceLongBreak`
        // is runtime state rather than config, so it is clamped here and
        // flushed through persistRuntime() — not the writeConfig() above.
        const clamped = Math.min(focusesSinceLongBreak, preset.sessionsUntilLongBreak);
        if (clamped !== focusesSinceLongBreak) {
            focusesSinceLongBreak = clamped;
            persistRuntime();
        }
    }

    function durationSecondsForPhase(targetPhase) {
        if (targetPhase === "longBreak") {
            return longBreakMinutes * 60;
        }
        if (targetPhase === "shortBreak") {
            return shortBreakMinutes * 60;
        }
        return focusMinutes * 60;
    }

    function formatTime(seconds) {
        const safeSeconds = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(safeSeconds / 60);
        const remainder = safeSeconds % 60;
        return String(minutes).padStart(2, "0") + ":" + String(remainder).padStart(2, "0");
    }

    function persistRuntime() {
        if (!initialized) {
            return;
        }
        Plasmoid.configuration.currentPhase = phase;
        Plasmoid.configuration.timerRunning = isRunning;
        Plasmoid.configuration.remainingSeconds = remainingSeconds;
        Plasmoid.configuration.phaseTotalSeconds = phaseTotalSeconds;
        Plasmoid.configuration.deadlineEpochMs = String(Math.round(deadlineMs));
        Plasmoid.configuration.focusesSinceLongBreak = focusesSinceLongBreak;
        Plasmoid.configuration.completedFocusSessions = completedFocusSessions;
        Plasmoid.configuration.completedFocusSessionsToday = completedFocusSessionsToday;
        Plasmoid.configuration.dailyCounterDate = dailyCounterDate;
        Plasmoid.configuration.dailyHistory = JSON.stringify(dailyHistory);
        Plasmoid.configuration.writeConfig();
    }

    function localDateKey(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, "0");
        const day = String(date.getDate()).padStart(2, "0");
        return year + "-" + month + "-" + day;
    }

    // Records a finished day. Days with nothing to show are not recorded, so the
    // stored array stays sparse: missing dates mean zero and must never be
    // backfilled with synthetic entries. Never called from the 250ms tick timer.
    function archiveDay(dateKey, count) {
        if (!dateKey || count <= 0) {
            return;
        }

        // `localDateKey()` is local-time based, so a DST transition or westward
        // travel can hand back a date key that is already stored. Replace the
        // existing entry in place instead of appending a duplicate.
        const entries = dailyHistory.slice();
        let replaced = false;
        for (let i = 0; i < entries.length; ++i) {
            if (entries[i] && entries[i][0] === dateKey) {
                entries[i] = [dateKey, count];
                replaced = true;
                break;
            }
        }
        if (!replaced) {
            entries.push([dateKey, count]);
        }

        dailyHistory = entries.slice(-90);
    }

    function ensureDailyCounterCurrent() {
        const today = localDateKey(new Date());
        if (dailyCounterDate === today) {
            return false;
        }
        // Archive the *outgoing* day first: the next two lines destroy the very
        // values being recorded.
        archiveDay(dailyCounterDate, completedFocusSessionsToday);
        dailyCounterDate = today;
        completedFocusSessionsToday = 0;
        persistRuntime();
        return true;
    }

    function resetDailyCount() {
        // Deliberately does NOT archive. This is the user's "I miscounted, clear
        // it" action, not a day boundary — the discarded count is wrong data the
        // user asked to be rid of, so writing it into the permanent history
        // would defeat the purpose. Please do not "fix" this by adding an
        // archiveDay() call here.
        dailyCounterDate = localDateKey(new Date());
        completedFocusSessionsToday = 0;
        persistRuntime();
    }

    function toggleTimer() {
        if (isRunning) {
            pauseTimer();
        } else {
            startTimer();
        }
    }

    function startTimer() {
        ensureDailyCounterCurrent();
        if (remainingSeconds <= 0 || remainingSeconds > phaseTotalSeconds) {
            phaseTotalSeconds = durationSecondsForPhase(phase);
            remainingSeconds = phaseTotalSeconds;
        }
        deadlineMs = Date.now() + remainingSeconds * 1000;
        isRunning = true;
        persistRuntime();
    }

    function pauseTimer() {
        if (!isRunning) {
            return;
        }
        remainingSeconds = Math.max(0, Math.ceil((deadlineMs - Date.now()) / 1000));
        isRunning = false;
        deadlineMs = 0;
        persistRuntime();
    }

    function resetCurrentInterval() {
        isRunning = false;
        deadlineMs = 0;
        phaseTotalSeconds = durationSecondsForPhase(phase);
        remainingSeconds = phaseTotalSeconds;
        persistRuntime();
    }

    function skipInterval() {
        moveToNextPhase(false, false);
    }

    function moveToNextPhase(countCompletedFocus, allowAutoStart) {
        const finishedPhase = phase;

        if (finishedPhase === "focus") {
            if (countCompletedFocus) {
                ensureDailyCounterCurrent();
                focusesSinceLongBreak += 1;
                completedFocusSessions += 1;
                completedFocusSessionsToday += 1;
            }
            phase = focusesSinceLongBreak >= sessionsUntilLongBreak ? "longBreak" : "shortBreak";
        } else {
            if (finishedPhase === "longBreak") {
                focusesSinceLongBreak = 0;
            }
            phase = "focus";
        }

        isRunning = false;
        deadlineMs = 0;
        phaseTotalSeconds = durationSecondsForPhase(phase);
        remainingSeconds = phaseTotalSeconds;
        persistRuntime();

        if (countCompletedFocus) {
            showCompletionNotification(finishedPhase);
        }

        if (allowAutoStart && (phase === "focus" ? autoStartFocus : autoStartBreaks)) {
            startTimer();
        }
    }

    function showCompletionNotification(finishedPhase) {
        pendingNotificationPhase = phase;

        // The event id is assigned per send, exactly like `title` and `text`
        // below, so that the two phases can carry different sounds without a
        // second Notification object. KNotification builds its configuration
        // from `componentName`/`eventId` inside sendEvent() — nothing is cached
        // from the previous send — so a reused object follows the change.
        completionNotification.eventId = finishedPhase === "focus"
            ? "focusFinished"
            : "breakFinished";

        if (finishedPhase === "focus") {
            completionNotification.title = focusDescription.length > 0
                ? i18n("Focus complete: %1", focusDescription)
                : i18n("Focus complete");
            completionNotification.text = phase === "longBreak"
                ? i18n("Pomodoro %1 for today is complete. Time for a %2-minute long break.",
                    completedFocusSessionsToday, longBreakMinutes)
                : i18n("Pomodoro %1 for today is complete. Time for a %2-minute break.",
                    completedFocusSessionsToday, shortBreakMinutes);
        } else {
            completionNotification.title = i18n("Break complete");
            completionNotification.text = i18n("Your next %1-minute focus interval is ready.", focusMinutes);
        }

        completionNotification.sendEvent();
    }

    function startIntervalFromNotification(expectedPhase) {
        if (phase === expectedPhase && !isRunning) {
            startTimer();
        } else {
            expanded = true;
        }
    }

    function settingChanged(affectedPhase) {
        if (!initialized || isRunning || phase !== affectedPhase) {
            return;
        }
        phaseTotalSeconds = durationSecondsForPhase(phase);
        remainingSeconds = phaseTotalSeconds;
        deadlineMs = 0;
        persistRuntime();
    }

    function setFocusMinutes(value) {
        Plasmoid.configuration.focusMinutes = Math.max(1, value);
        Plasmoid.configuration.writeConfig();
    }

    function setShortBreakMinutes(value) {
        Plasmoid.configuration.shortBreakMinutes = Math.max(1, value);
        Plasmoid.configuration.writeConfig();
    }

    function setLongBreakMinutes(value) {
        Plasmoid.configuration.longBreakMinutes = Math.max(1, value);
        Plasmoid.configuration.writeConfig();
    }

    function setSessionsUntilLongBreak(value) {
        Plasmoid.configuration.sessionsUntilLongBreak = Math.max(1, value);
        Plasmoid.configuration.writeConfig();
    }

    function setFocusDescription(value) {
        const normalized = value.trim();
        if (Plasmoid.configuration.focusDescription === normalized) {
            return;
        }
        Plasmoid.configuration.focusDescription = normalized;
        Plasmoid.configuration.writeConfig();
    }

    onFocusMinutesChanged: settingChanged("focus")
    onShortBreakMinutesChanged: settingChanged("shortBreak")
    onLongBreakMinutesChanged: settingChanged("longBreak")

    Timer {
        interval: 250
        repeat: true
        running: root.isRunning
        onTriggered: {
            const nextRemaining = Math.max(0, Math.ceil((root.deadlineMs - Date.now()) / 1000));
            if (nextRemaining !== root.remainingSeconds) {
                root.remainingSeconds = nextRemaining;
            }
            if (nextRemaining <= 0) {
                root.moveToNextPhase(true, true);
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.ensureDailyCounterCurrent()
    }

    Notification {
        id: completionNotification

        // This widget's own notification component, shipped as
        // notifications/org.kde.plasma.pomodoro.notifyrc. KNotifications only
        // reads knotifications6/ under the XDG data dirs, and a plasmoid
        // package installs to plasma/plasmoids/, so install.sh copies the file
        // into ~/.local/share/knotifications6/ — see the README.
        //
        // Previously this pointed at "plasma_applet_timer"/"timerFinished",
        // the stock Timer applet's component: sound and urgency changes made
        // for one applied to the other, and one event could not distinguish
        // the end of a focus interval from the end of a break.
        //
        // `eventId` is deliberately absent here — showCompletionNotification()
        // sets it per send.
        componentName: "org.kde.plasma.pomodoro"
        iconName: "chronometer"
        flags: Notification.Persistent | Notification.SkipGrouping
        urgency: Notification.HighUrgency

        defaultAction: NotificationAction {
            label: i18n("Open Pomodoro")
            onActivated: root.expanded = true
        }

        actions: [
            NotificationAction {
                label: root.notificationActionLabel
                onActivated: root.startIntervalFromNotification(root.pendingNotificationPhase)
            }
        ]
    }

    Component.onCompleted: {
        // Must run before any other restore logic and, critically, before
        // `initialized = true` — persistRuntime() is a no-op until then, so the
        // first write back always carries the real stored history. Parsing any
        // later would let that first persist clobber it with an empty array.
        // A corrupt or hand-edited value degrades to empty rather than throwing
        // out of Component.onCompleted and leaving the widget half-restored.
        dailyHistory = [];
        try {
            const savedHistory = JSON.parse(Plasmoid.configuration.dailyHistory || "[]");
            if (Array.isArray(savedHistory)) {
                dailyHistory = savedHistory;
            }
        } catch (error) {
            dailyHistory = [];
        }

        const savedPhase = Plasmoid.configuration.currentPhase;
        phase = savedPhase === "shortBreak" || savedPhase === "longBreak" ? savedPhase : "focus";
        focusesSinceLongBreak = Math.max(0, Plasmoid.configuration.focusesSinceLongBreak);
        completedFocusSessions = Math.max(0, Plasmoid.configuration.completedFocusSessions);

        const today = localDateKey(new Date());
        if (Plasmoid.configuration.dailyCounterDate === today) {
            dailyCounterDate = today;
            completedFocusSessionsToday = Math.max(0, Plasmoid.configuration.completedFocusSessionsToday);
        } else {
            // The common rollover path in practice: the shell usually restarts
            // overnight, and the 30-second poll timer only catches a boundary
            // that happens while the shell is actually running. Archive the
            // saved day from the stored values before overwriting them.
            archiveDay(Plasmoid.configuration.dailyCounterDate,
                Math.max(0, Plasmoid.configuration.completedFocusSessionsToday));
            dailyCounterDate = today;
            completedFocusSessionsToday = 0;
        }

        const savedPhaseTotal = Plasmoid.configuration.phaseTotalSeconds;
        phaseTotalSeconds = savedPhaseTotal > 0
            ? savedPhaseTotal
            : durationSecondsForPhase(phase);
        const savedRemaining = Plasmoid.configuration.remainingSeconds;
        remainingSeconds = savedRemaining > 0 && savedRemaining <= phaseTotalSeconds
            ? savedRemaining
            : phaseTotalSeconds;

        deadlineMs = Number(Plasmoid.configuration.deadlineEpochMs) || 0;
        initialized = true;

        if (Plasmoid.configuration.timerRunning && deadlineMs > Date.now()) {
            remainingSeconds = Math.max(1, Math.ceil((deadlineMs - Date.now()) / 1000));
            isRunning = true;
            persistRuntime();
        } else if (Plasmoid.configuration.timerRunning && deadlineMs > 0) {
            remainingSeconds = 0;
            moveToNextPhase(true, false);
        } else {
            isRunning = false;
            deadlineMs = 0;
            persistRuntime();
        }
    }
}
