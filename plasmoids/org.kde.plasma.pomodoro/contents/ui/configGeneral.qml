import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: page

    property alias cfg_focusMinutes: focusMinutes.value
    property alias cfg_shortBreakMinutes: shortBreakMinutes.value
    property alias cfg_longBreakMinutes: longBreakMinutes.value
    property alias cfg_sessionsUntilLongBreak: sessionsUntilLongBreak.value
    property alias cfg_autoStartBreaks: autoStartBreaks.checked
    property alias cfg_autoStartFocus: autoStartFocus.checked
    property alias cfg_showInlineSettings: showInlineSettings.checked

    readonly property PresetTable presetTable: PresetTable {}
    // Derived from the four editors below, not from a stored key, and derived
    // from the *staged* values rather than Plasmoid.configuration so the combo
    // box tracks edits the user has not applied yet.
    readonly property int activePresetIndex: presetTable.matchingIndex(
        focusMinutes.value,
        shortBreakMinutes.value,
        longBreakMinutes.value,
        sessionsUntilLongBreak.value)
    readonly property int customIndex: presetTable.list.length

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.ComboBox {
            id: presetSelector

            Kirigami.FormData.label: i18n("Preset:")
            // "Custom" is not a preset, it is the name for "these four values
            // match none of them". It is listed so the box has something honest
            // to show, and selecting it deliberately does nothing: there is no
            // set of durations called Custom to apply.
            model: page.presetTable.list.map(preset => preset.name)
                .concat([i18nc("No preset matches the current durations", "Custom")])
            currentIndex: page.activePresetIndex >= 0 ? page.activePresetIndex : page.customIndex

            // `onActivated`, never `onCurrentIndexChanged`. This is not style.
            // The binding above rewrites currentIndex whenever a duration
            // changes, and `onCurrentIndexChanged` cannot tell that write apart
            // from a user selection, so it would apply a preset in response to
            // its own effect and fight anyone editing a spin box. `onActivated`
            // fires only for user selection — the same rule DurationEditor
            // follows with `onValueModified`.
            onActivated: index => {
                if (index >= 0 && index < page.presetTable.list.length) {
                    const preset = page.presetTable.list[index];
                    focusMinutes.value = preset.focusMinutes;
                    shortBreakMinutes.value = preset.shortBreakMinutes;
                    longBreakMinutes.value = preset.longBreakMinutes;
                    sessionsUntilLongBreak.value = preset.sessionsUntilLongBreak;
                }
                // Selecting "Custom", or re-selecting the preset already in
                // effect, leaves the durations untouched, so `activePresetIndex`
                // never re-emits and the binding never re-evaluates to undo the
                // combo box's own internal write. Re-arm it — through the id,
                // because a bare `currentIndex = ...` in a handler is a plain
                // JavaScript assignment that invents a variable rather than
                // writing the property.
                presetSelector.currentIndex = Qt.binding(() => page.activePresetIndex >= 0
                    ? page.activePresetIndex
                    : page.customIndex);
            }
        }

        DurationEditor {
            id: focusMinutes

            Kirigami.FormData.label: i18n("Focus interval:")
        }

        DurationEditor {
            id: shortBreakMinutes

            Kirigami.FormData.label: i18n("Short break:")
        }

        DurationEditor {
            id: sessionsUntilLongBreak

            Kirigami.FormData.label: i18n("Focuses before long break:")
            // Counts focuses, not minutes, so the suffix is blanked -- but the
            // column keeps its width so this row stays aligned with the three
            // duration rows around it.
            suffix: ""
            from: 1
            to: 12
        }

        DurationEditor {
            id: longBreakMinutes

            Kirigami.FormData.label: i18n("Long break:")
        }

        QQC2.CheckBox {
            id: showInlineSettings

            Kirigami.FormData.label: i18n("Popup:")
            text: i18n("Repeat these settings inside the widget popup")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Behaviour")
        }

        QQC2.CheckBox {
            id: autoStartBreaks

            Kirigami.FormData.label: i18n("Auto-start:")
            text: i18n("Start breaks automatically")
        }

        QQC2.CheckBox {
            id: autoStartFocus

            text: i18n("Start focus intervals automatically")
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Timer durations are configured here. A running interval keeps its original deadline; changes apply when it is paused or restarted.")
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
