pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

MouseArea {
    id: compact

    required property var controller
    readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
    readonly property real ringSize: Math.max(Kirigami.Units.iconSizes.small,
        Math.min(horizontal ? height - Kirigami.Units.smallSpacing : width - Kirigami.Units.smallSpacing,
            Kirigami.Units.iconSizes.smallMedium))

    Layout.minimumWidth: horizontal ? content.implicitWidth + Kirigami.Units.smallSpacing * 2 : Kirigami.Units.gridUnit * 2
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: horizontal ? Kirigami.Units.gridUnit * 17 : Infinity
    Layout.minimumHeight: horizontal ? Kirigami.Units.gridUnit : Kirigami.Units.gridUnit * 2
    Layout.preferredHeight: Layout.minimumHeight

    hoverEnabled: true
    onClicked: compact.controller.expanded = !compact.controller.expanded

    RowLayout {
        id: content

        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        Item {
            implicitWidth: compact.ringSize
            implicitHeight: compact.ringSize

            Canvas {
                id: progressRing

                anchors.fill: parent
                antialiasing: true

                Connections {
                    target: compact.controller
                    function onProgressChanged() { progressRing.requestPaint(); }
                    function onAccentColorChanged() { progressRing.requestPaint(); }
                }

                onPaint: {
                    const ctx = getContext("2d");
                    const lineWidth = Math.max(2, width * 0.12);
                    const radius = Math.max(1, Math.min(width, height) / 2 - lineWidth / 2);
                    const centerX = width / 2;
                    const centerY = height / 2;
                    ctx.clearRect(0, 0, width, height);
                    ctx.lineWidth = lineWidth;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Qt.rgba(Kirigami.Theme.textColor.r,
                        Kirigami.Theme.textColor.g,
                        Kirigami.Theme.textColor.b,
                        0.20);
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                    ctx.stroke();
                    if (compact.controller.progress > 0) {
                        ctx.strokeStyle = compact.controller.accentColor;
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, -Math.PI / 2,
                            -Math.PI / 2 + Math.PI * 2 * compact.controller.progress);
                        ctx.stroke();
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.max(3, parent.width * 0.22)
                height: width
                radius: width / 2
                color: compact.controller.accentColor
                opacity: compact.controller.isRunning ? 1 : 0.55
            }
        }

        Text {
            visible: compact.horizontal
            text: compact.controller.formattedTime
            color: Kirigami.Theme.textColor
            font.weight: Font.DemiBold
        }

        RowLayout {
            visible: compact.horizontal
            spacing: Kirigami.Units.smallSpacing / 2

            Rectangle {
                implicitWidth: Kirigami.Units.smallSpacing
                implicitHeight: implicitWidth
                radius: width / 2
                color: compact.controller.accentColor
            }

            Text {
                text: compact.controller.completedFocusSessionsToday
                color: Kirigami.Theme.textColor
                opacity: 0.82
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            visible: compact.horizontal && compact.controller.focusDescription.length > 0
            implicitWidth: Kirigami.Units.smallSpacing / 2
            implicitHeight: content.height * 0.46
            radius: width / 2
            color: Kirigami.Theme.textColor
            opacity: 0.25
        }

        Text {
            visible: compact.horizontal && compact.controller.focusDescription.length > 0
            Layout.maximumWidth: Kirigami.Units.gridUnit * 7
            text: compact.controller.focusDescription
            color: Kirigami.Theme.textColor
            opacity: 0.82
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
