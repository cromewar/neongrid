pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.AbstractButton {
    id: button

    required property var controller

    implicitWidth: Kirigami.Units.gridUnit * 7
    implicitHeight: Kirigami.Units.gridUnit * 2.35
    text: controller.isRunning ? i18n("Pause") : i18n("Start")
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    onClicked: controller.toggleTimer()

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius
        color: button.down
            ? Qt.darker(button.controller.accentColor, 1.38)
            : (button.hovered
                ? Qt.darker(button.controller.accentColor, 1.13)
                : Qt.darker(button.controller.accentColor, 1.25))
        border.width: button.activeFocus ? 2 : 0
        border.color: button.controller.accentForegroundColor

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Item { Layout.fillWidth: true }

        Canvas {
            id: playbackSymbol

            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: implicitWidth
            antialiasing: true

            Connections {
                target: button.controller
                function onIsRunningChanged() { playbackSymbol.requestPaint(); }
                // A Canvas does not repaint when a colour it read last time
                // changes, so a live colour-scheme switch would leave the glyph
                // in the old foreground until something else invalidated it.
                function onAccentForegroundColorChanged() { playbackSymbol.requestPaint(); }
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = button.controller.accentForegroundColor;
                if (button.controller.isRunning) {
                    const barWidth = width * 0.24;
                    const barHeight = height * 0.72;
                    const top = (height - barHeight) / 2;
                    ctx.fillRect(width * 0.20, top, barWidth, barHeight);
                    ctx.fillRect(width * 0.56, top, barWidth, barHeight);
                } else {
                    ctx.beginPath();
                    ctx.moveTo(width * 0.28, height * 0.14);
                    ctx.lineTo(width * 0.82, height * 0.50);
                    ctx.lineTo(width * 0.28, height * 0.86);
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }

        QQC2.Label {
            text: button.text
            color: button.controller.accentForegroundColor
            font.weight: Font.DemiBold
        }

        Item { Layout.fillWidth: true }
    }

    QQC2.ToolTip.visible: hovered
    QQC2.ToolTip.text: controller.isRunning ? i18n("Pause the current interval") : i18n("Start the current interval")
}
