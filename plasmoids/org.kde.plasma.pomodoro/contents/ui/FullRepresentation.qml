pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: full

    required property var controller

    // Separator, header and four spin box rows plus their spacing, measured at
    // ~11 gridUnits. The popup has to ask for this outright: the only flexible
    // item is the spacer at the bottom, so anything short clips the last row
    // rather than compressing gracefully.
    readonly property int inlineSettingsHeight: controller.showInlineSettings
        ? Kirigami.Units.gridUnit * 11
        : 0

    implicitWidth: Kirigami.Units.gridUnit * 21
    implicitHeight: Kirigami.Units.gridUnit * 21 + inlineSettingsHeight
    Layout.minimumWidth: Kirigami.Units.gridUnit * 19
    Layout.minimumHeight: Kirigami.Units.gridUnit * 19 + inlineSettingsHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    // The popup can be hidden without the field ever losing keyboard focus.
    onVisibleChanged: {
        if (!visible) {
            focusField.commit();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                implicitWidth: phaseLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
                implicitHeight: phaseLabel.implicitHeight + Kirigami.Units.smallSpacing * 1.5
                radius: height / 2
                color: Qt.rgba(full.controller.accentColor.r,
                    full.controller.accentColor.g,
                    full.controller.accentColor.b,
                    0.16)

                QQC2.Label {
                    id: phaseLabel

                    anchors.centerIn: parent
                    text: full.controller.phaseName.toUpperCase()
                    color: full.controller.accentColor
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.7
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    implicitWidth: Kirigami.Units.smallSpacing * 1.4
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: full.controller.accentColor
                }

                QQC2.Label {
                    text: i18n("%1 today", full.controller.completedFocusSessionsToday)
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                }
            }
        }

        Item {
            id: ring

            // The stroke width the Canvas paints with. Hoisted out of onPaint so
            // the text below can be sized against the same number instead of
            // re-deriving it and drifting.
            readonly property real lineWidth: Math.max(7, width * 0.055)
            // The stroke is centred on `radius`, so its inner edge sits half a
            // line width further in: usable diameter is width - 3 * lineWidth.
            // Text is a rectangle inside a circle, so it cannot use the full
            // diameter — at the height of a two-line stack the chord is ~96% of
            // it, and 0.82 keeps the widest line clear of the curve with margin.
            readonly property real contentWidth: (width - lineWidth * 3) * 0.82

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Kirigami.Units.gridUnit * 10
            implicitHeight: implicitWidth

            Canvas {
                id: timerRing

                anchors.fill: parent
                antialiasing: true

                Connections {
                    target: full.controller
                    function onProgressChanged() { timerRing.requestPaint(); }
                    function onAccentColorChanged() { timerRing.requestPaint(); }
                }

                onPaint: {
                    const ctx = getContext("2d");
                    const lineWidth = ring.lineWidth;
                    const radius = Math.min(width, height) / 2 - lineWidth;
                    const centerX = width / 2;
                    const centerY = height / 2;
                    ctx.clearRect(0, 0, width, height);
                    ctx.lineWidth = lineWidth;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Qt.rgba(Kirigami.Theme.textColor.r,
                        Kirigami.Theme.textColor.g,
                        Kirigami.Theme.textColor.b,
                        0.10);
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                    ctx.stroke();
                    if (full.controller.progress > 0) {
                        ctx.strokeStyle = full.controller.accentColor;
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, -Math.PI / 2,
                            -Math.PI / 2 + Math.PI * 2 * full.controller.progress);
                        ctx.stroke();
                    }
                }
            }

            // Both labels are width-constrained and set to shrink rather than
            // overflow. Without this they size to their content and run straight
            // through the stroke — "Ready when you are" always did, and
            // formattedTime does too once the focus interval passes 99 minutes
            // and the countdown grows a sixth character.
            Column {
                anchors.centerIn: parent
                width: ring.contentWidth
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: full.controller.formattedTime
                    color: Kirigami.Theme.textColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 3.0
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: Kirigami.Theme.defaultFont.pixelSize
                    font.weight: Font.Light
                }

                QQC2.Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: full.controller.isRunning
                        ? i18n("Ends %1", full.controller.estimatedFinishTime)
                        : i18n("Ready when you are")
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.75)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: i18n("CURRENT FOCUS")
                color: Kirigami.Theme.disabledTextColor
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.TextField {
                    id: focusField

                    // `text` is deliberately not bound to the controller. The stored
                    // description is trimmed, and the config map re-emits its change
                    // signal on every write, so a binding would swallow spaces and
                    // send the cursor to the end while the user is still typing.
                    readonly property string committedDescription: full.controller.focusDescription

                    function commit() {
                        descriptionCommit.stop();
                        full.controller.setFocusDescription(text);
                    }

                    function revert() {
                        descriptionCommit.stop();
                        text = committedDescription;
                        cursorPosition = text.length;
                    }

                    Layout.fillWidth: true
                    placeholderText: i18n("What are you focusing on?")
                    selectByMouse: true
                    persistentSelection: true
                    maximumLength: 120

                    onTextEdited: descriptionCommit.restart()
                    onEditingFinished: commit()
                    onAccepted: {
                        commit();
                        // Show the normalised value once the user is done typing.
                        text = committedDescription;
                        cursorPosition = text.length;
                    }
                    // Follow external changes (config dialog, another instance) only
                    // while this field is idle, so editing is never interrupted.
                    onCommittedDescriptionChanged: {
                        if (!activeFocus && text !== committedDescription) {
                            text = committedDescription;
                        }
                    }

                    Keys.onEscapePressed: event => {
                        revert();
                        event.accepted = true;
                    }

                    Component.onCompleted: text = committedDescription

                    Timer {
                        id: descriptionCommit

                        interval: 600
                        onTriggered: full.controller.setFocusDescription(focusField.text)
                    }
                }

                QQC2.ToolButton {
                    icon.name: "edit-clear"
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Clear focus")
                    visible: focusField.text.length > 0
                    onClicked: {
                        focusField.clear();
                        focusField.commit();
                        focusField.forceActiveFocus();
                    }
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: text
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: full.controller.sessionsUntilLongBreak

                delegate: Rectangle {
                    required property int index

                    implicitWidth: index < full.controller.focusesSinceLongBreak
                        ? Kirigami.Units.gridUnit
                        : Kirigami.Units.smallSpacing * 1.4
                    implicitHeight: Kirigami.Units.smallSpacing * 1.4
                    radius: height / 2
                    color: index < full.controller.focusesSinceLongBreak
                        ? full.controller.accentColor
                        : Kirigami.Theme.textColor
                    opacity: index < full.controller.focusesSinceLongBreak ? 0.90 : 0.18

                    Behavior on implicitWidth {
                        NumberAnimation { duration: Kirigami.Units.shortDuration }
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.largeSpacing

            QQC2.ToolButton {
                icon.name: "view-refresh"
                text: i18n("Restart")
                display: QQC2.AbstractButton.TextUnderIcon
                onClicked: full.controller.resetCurrentInterval()
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Restart this interval")
            }

            PlaybackButton {
                controller: full.controller
            }

            QQC2.ToolButton {
                icon.name: "media-skip-forward"
                text: i18n("Skip")
                display: QQC2.AbstractButton.TextUnderIcon
                onClicked: full.controller.skipInterval()
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Move to the next interval")
            }
        }

        // The full popup. Off by default -- the compact popup keeps durations in
        // the config dialog -- but retuning the timer without leaving the popup
        // is a reasonable thing to want, so it is the user's call rather than
        // ours. Layouts drop invisible items, so the compact popup pays nothing
        // for this beyond the two bindings.
        Kirigami.Separator {
            Layout.fillWidth: true
            visible: full.controller.showInlineSettings
        }

        RowLayout {
            Layout.fillWidth: true
            visible: full.controller.showInlineSettings

            QQC2.Label {
                text: i18n("Timer settings")
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            QQC2.Label {
                text: i18n("Changes apply to paused intervals")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }
        }

        GridLayout {
            Layout.fillWidth: true
            visible: full.controller.showInlineSettings
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                // fillWidth on the label column, not the editors: Layout.alignment
                // only positions an item inside its own cell, and the editor
                // column is exactly as wide as its content. Without a column
                // that absorbs the slack it pools to the right of the editors
                // instead of pushing them against the popup edge.
                Layout.fillWidth: true
                text: i18n("Focus interval")
            }
            DurationEditor {
                Layout.alignment: Qt.AlignRight
                value: full.controller.focusMinutes
                onValueEdited: value => full.controller.setFocusMinutes(value)
            }

            QQC2.Label {
                // fillWidth on the label column, not the editors: Layout.alignment
                // only positions an item inside its own cell, and the editor
                // column is exactly as wide as its content. Without a column
                // that absorbs the slack it pools to the right of the editors
                // instead of pushing them against the popup edge.
                Layout.fillWidth: true
                text: i18n("Short break")
            }
            DurationEditor {
                Layout.alignment: Qt.AlignRight
                value: full.controller.shortBreakMinutes
                onValueEdited: value => full.controller.setShortBreakMinutes(value)
            }

            QQC2.Label {
                // fillWidth on the label column, not the editors: Layout.alignment
                // only positions an item inside its own cell, and the editor
                // column is exactly as wide as its content. Without a column
                // that absorbs the slack it pools to the right of the editors
                // instead of pushing them against the popup edge.
                Layout.fillWidth: true
                text: i18n("Focuses before long break")
            }
            // A DurationEditor with the suffix blanked rather than a bare
            // SpinBox: it keeps the "min" column's width, so this spin box lines
            // up with the three duration rows instead of sitting a word further
            // right than all of them.
            DurationEditor {
                Layout.alignment: Qt.AlignRight
                suffix: ""
                from: 1
                to: 12
                value: full.controller.sessionsUntilLongBreak
                onValueEdited: value => full.controller.setSessionsUntilLongBreak(value)
            }

            QQC2.Label {
                // fillWidth on the label column, not the editors: Layout.alignment
                // only positions an item inside its own cell, and the editor
                // column is exactly as wide as its content. Without a column
                // that absorbs the slack it pools to the right of the editors
                // instead of pushing them against the popup edge.
                Layout.fillWidth: true
                text: i18n("Long break")
            }
            DurationEditor {
                Layout.alignment: Qt.AlignRight
                value: full.controller.longBreakMinutes
                onValueEdited: value => full.controller.setLongBreakMinutes(value)
            }
        }

        Item { Layout.fillHeight: true }
    }
}
