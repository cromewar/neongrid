import QtQuick

// The single source of truth for the built-in interval presets.
//
// Two unrelated roots need it — the right-click menu lives in main.qml, the
// settings dialog's combo box in configGeneral.qml, and a config page has no
// handle on the plasmoid's root item — so the table lives in a component both
// can instantiate. Both files sit in this directory, so the implicit import
// resolves this with no qmldir, exactly as configGeneral.qml already picks up
// DurationEditor.qml.
//
// Keeping one copy is a correctness requirement, not tidiness: two tables that
// drifted apart would let the settings dialog report "Deep work" for a set of
// durations the context menu considers Custom.
//
// Deliberately three fixed built-ins. User-defined presets would need storage,
// naming, renaming, reordering and deletion — a preset manager, which is an
// application, not a panel widget.
QtObject {
    id: table

    readonly property var list: [
        {
            name: i18nc("Interval preset: the traditional 25/5/15 Pomodoro cycle", "Classic"),
            focusMinutes: 25,
            shortBreakMinutes: 5,
            longBreakMinutes: 15,
            sessionsUntilLongBreak: 4
        },
        {
            name: i18nc("Interval preset: longer focus blocks", "Deep work"),
            focusMinutes: 50,
            shortBreakMinutes: 10,
            longBreakMinutes: 30,
            sessionsUntilLongBreak: 2
        },
        {
            name: i18nc("Interval preset: very long focus blocks", "Long haul"),
            focusMinutes: 90,
            shortBreakMinutes: 20,
            longBreakMinutes: 30,
            sessionsUntilLongBreak: 2
        }
    ]

    // Which preset the four given durations add up to, or -1 for "Custom".
    //
    // The active preset is derived on every read rather than stored. A saved
    // "selected preset" key would claim "Deep work" for the rest of time the
    // moment the user nudged a single duration, and would need a migration to
    // introduce. Nothing to desync if nothing is written.
    function matchingIndex(focusMinutes, shortBreakMinutes, longBreakMinutes, sessionsUntilLongBreak) {
        for (let i = 0; i < table.list.length; ++i) {
            const preset = table.list[i];
            if (preset.focusMinutes === focusMinutes
                && preset.shortBreakMinutes === shortBreakMinutes
                && preset.longBreakMinutes === longBreakMinutes
                && preset.sessionsUntilLongBreak === sessionsUntilLongBreak) {
                return i;
            }
        }
        return -1;
    }
}
