import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// A tidy grid of thumbnails with names underneath, on a floating card.
// The card draws itself (the dialog is frameless) so it always hugs its
// content and can be lifted clear of the panel, whatever size the shell
// gives the popup window.
Item {
    id: grid

    property var files: []
    property int extraCount: 0
    property int iconSize: 64
    property int columns: 3
    property string folderPath: ""
    property bool active: false
    property bool up: true

    signal openFile(var url)
    signal openFolder()
    signal closeRequested()

    readonly property int n: files.length
    readonly property int cols: Math.max(1, Math.min(columns, Math.max(1, n)))
    readonly property real cellW: Math.max(iconSize + Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 5.5)
    readonly property real cellH: iconSize + Kirigami.Units.gridUnit * 2.8
    readonly property int pad: Kirigami.Units.largeSpacing

    // Gap between the card and the panel edge it springs from.
    readonly property real panelInset: Math.round(Kirigami.Units.gridUnit * 2)
    readonly property real availH: Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight : 1000

    readonly property int gridRows: n > 0 ? Math.ceil(n / cols) : 1
    readonly property real gridH: n > 0 ? gridRows * cellH : Kirigami.Units.gridUnit * 4
    readonly property real chromeH: pad * 2 + header.implicitHeight
        + Kirigami.Units.smallSpacing * 3 + sep.height
    readonly property real naturalCardH: chromeH + gridH
    // Grow with the content up to a comfortable limit, then scroll — so a lot of
    // files don't stretch the card to the full height of the screen. Grid cells
    // are tall, so this is tighter than the list's to reach the limit sooner.
    readonly property real maxCardH: availH * 0.55 - panelInset
    readonly property real cardH: Math.min(naturalCardH, maxCardH)
    readonly property real cardW: Math.max(cols * cellW, Kirigami.Units.gridUnit * 12) + pad * 2

    implicitWidth: cardW
    implicitHeight: cardH + panelInset

    // Clicking the transparent margin around the card dismisses it.
    MouseArea {
        anchors.fill: parent
        onClicked: grid.closeRequested()
    }

    // Scroll with the mouse wheel or a two-finger trackpad gesture from anywhere
    // over the card. Kept at the root (not inside the Flickable, which would
    // reparent it into the scrolling content and miss events).
    WheelHandler {
        enabled: gridFlick.overflow
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            var dy = event.pixelDelta.y;
            if (dy === 0)
                dy = event.angleDelta.y / 120 * grid.cellH * 0.6;
            var maxY = gridFlick.contentHeight - gridFlick.height;
            gridFlick.contentY = Math.max(0, Math.min(maxY, gridFlick.contentY - dy));
        }
    }

    Kirigami.ShadowedRectangle {
        id: card
        width: grid.cardW
        height: grid.cardH
        anchors.horizontalCenter: parent.horizontalCenter
        // Sit at the panel end of the popup, a gap short of the edge.
        y: grid.up ? (grid.height - grid.panelInset - height) : grid.panelInset

        radius: Kirigami.Units.largeSpacing
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        shadow.size: 18
        shadow.color: Qt.rgba(0, 0, 0, 0.35)
        shadow.yOffset: 3

        opacity: grid.active ? 1.0 : 0.0
        scale: grid.active ? 1.0 : 0.96
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: grid.pad
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                id: header
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon {
                    source: "folder-download"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }
                Kirigami.Heading {
                    level: 4
                    text: i18n("Downloads")
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                PlasmaComponents.ToolButton {
                    icon.name: "folder-open-symbolic"
                    text: grid.extraCount > 0 ? i18n("Show all (%1)", grid.n + grid.extraCount) : i18n("Open folder")
                    display: PlasmaComponents.AbstractButton.TextBesideIcon
                    onClicked: grid.openFolder()
                }
            }

            Kirigami.Separator { id: sep; Layout.fillWidth: true }

            PlasmaComponents.Label {
                visible: grid.n === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: 0.7
                text: i18n("No recent downloads")
            }

            Flickable {
                id: gridFlick
                visible: grid.n > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: theGrid.height
                contentWidth: width
                clip: true
                // Drag drags a file out; scroll via wheel/trackpad or the scrollbar.
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                readonly property bool overflow: contentHeight > height

                QQC2.ScrollBar.vertical: HoverScrollBar {
                    policy: gridFlick.overflow ? QQC2.ScrollBar.AlwaysOn : QQC2.ScrollBar.AlwaysOff
                }

                Grid {
                    id: theGrid
                    columns: grid.cols
                    columnSpacing: 0
                    rowSpacing: 0
                    x: Math.max(0, (gridFlick.width - width) / 2)

                    Repeater {
                        model: grid.files
                        delegate: FileDragItem {
                            id: cell
                            required property int index
                            required property var modelData
                            width: grid.cellW
                            height: grid.cellH
                            fileUrl: modelData.url
                            fileName: modelData.name
                            isDir: modelData.isDir

                            opacity: grid.active ? 1.0 : 0.0
                            scale: grid.active ? 1.0 : 0.85
                            Behavior on opacity { SequentialAnimation {
                                PauseAnimation { duration: grid.active ? index * 18 : 0 }
                                NumberAnimation { duration: 160 }
                            } }
                            Behavior on scale { SequentialAnimation {
                                PauseAnimation { duration: grid.active ? index * 18 : 0 }
                                NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                            } }

                            onClicked: grid.openFile(modelData.url)

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing / 2
                                radius: Kirigami.Units.smallSpacing
                                color: Kirigami.Theme.highlightColor
                                opacity: cell.hovered ? 0.18 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                spacing: Kirigami.Units.smallSpacing
                                FileThumb {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: grid.iconSize
                                    Layout.preferredHeight: grid.iconSize
                                    fileName: modelData.name
                                    fileUrl: modelData.url
                                    isDir: modelData.isDir
                                }
                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: modelData.name
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignTop
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    font: Kirigami.Theme.smallFont
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
