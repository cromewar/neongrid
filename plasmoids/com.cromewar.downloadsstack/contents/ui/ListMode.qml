import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "IconTools.js" as IconTools

// A compact list, one file per row, on a floating card. The card draws
// itself (frameless dialog) so it always hugs its content and sits clear
// of the panel it springs from.
Item {
    id: list

    property var files: []
    property int extraCount: 0
    property int iconSize: 64
    property string folderPath: ""
    property bool active: false
    property bool up: true

    signal openFile(var url)
    signal openFolder()
    signal closeRequested()

    readonly property int n: files.length
    readonly property real rowIconSize: Math.min(iconSize, Kirigami.Units.iconSizes.medium)
    readonly property real rowH: rowIconSize + Kirigami.Units.smallSpacing * 3
    readonly property int pad: Kirigami.Units.largeSpacing

    readonly property real panelInset: Math.round(Kirigami.Units.gridUnit * 2)
    readonly property real availH: Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight : 1000

    readonly property real listH: n > 0 ? n * rowH : Kirigami.Units.gridUnit * 4
    readonly property real chromeH: pad * 2 + header.implicitHeight
        + Kirigami.Units.smallSpacing * 2 + sep.height
    readonly property real naturalCardH: chromeH + listH
    // Grow with the content up to a comfortable limit, then scroll — so a lot of
    // files don't stretch the card to the full height of the screen.
    readonly property real maxCardH: availH * 0.6 - panelInset
    readonly property real cardH: Math.min(naturalCardH, maxCardH)
    readonly property real cardW: Kirigami.Units.gridUnit * 17

    implicitWidth: cardW
    implicitHeight: cardH + panelInset

    MouseArea {
        anchors.fill: parent
        onClicked: list.closeRequested()
    }

    // Scroll with the mouse wheel or a two-finger trackpad gesture from anywhere
    // over the card. Kept at the root (not inside the ListView, which would
    // reparent it into the scrolling content and miss events).
    WheelHandler {
        enabled: listView.overflow
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            var dy = event.pixelDelta.y;
            if (dy === 0)
                dy = event.angleDelta.y / 120 * list.rowH * 1.5;
            var maxY = listView.contentHeight - listView.height;
            listView.contentY = Math.max(0, Math.min(maxY, listView.contentY - dy));
        }
    }

    Kirigami.ShadowedRectangle {
        id: card
        width: list.cardW
        height: list.cardH
        anchors.horizontalCenter: parent.horizontalCenter
        y: list.up ? (list.height - list.panelInset - height) : list.panelInset

        radius: Kirigami.Units.largeSpacing
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        shadow.size: 18
        shadow.color: Qt.rgba(0, 0, 0, 0.35)
        shadow.yOffset: 3

        opacity: list.active ? 1.0 : 0.0
        scale: list.active ? 1.0 : 0.96
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: list.pad
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
                    text: list.extraCount > 0 ? i18n("Show all (%1)", list.n + list.extraCount) : i18n("Open folder")
                    display: PlasmaComponents.AbstractButton.TextBesideIcon
                    onClicked: list.openFolder()
                }
            }

            Kirigami.Separator { id: sep; Layout.fillWidth: true }

            PlasmaComponents.Label {
                visible: list.n === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: 0.7
                text: i18n("No recent downloads")
            }

            ListView {
                id: listView
                visible: list.n > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: list.files
                clip: true
                // Drag drags a file out; scroll via wheel/trackpad or the scrollbar.
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                readonly property bool overflow: contentHeight > height

                QQC2.ScrollBar.vertical: HoverScrollBar {
                    policy: listView.overflow ? QQC2.ScrollBar.AlwaysOn : QQC2.ScrollBar.AlwaysOff
                }

                delegate: FileDragItem {
                    id: row
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    height: list.rowH
                    fileUrl: modelData.url
                    fileName: modelData.name
                    isDir: modelData.isDir

                    opacity: list.active ? 1.0 : 0.0
                    Behavior on opacity { SequentialAnimation {
                        PauseAnimation { duration: list.active ? Math.min(index, 12) * 18 : 0 }
                        NumberAnimation { duration: 150 }
                    } }

                    onClicked: list.openFile(modelData.url)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.highlightColor
                        opacity: row.hovered ? 0.18 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        FileThumb {
                            Layout.preferredWidth: list.rowIconSize
                            Layout.preferredHeight: list.rowIconSize
                            Layout.alignment: Qt.AlignVCenter
                            fileName: modelData.name
                            fileUrl: modelData.url
                            isDir: modelData.isDir
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: modelData.name
                                elide: Text.ElideMiddle
                                maximumLineCount: 1
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: i18n(IconTools.kindOf(modelData.name, modelData.isDir))
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                opacity: 0.65
                                font: Kirigami.Theme.smallFont
                            }
                        }
                        Kirigami.Icon {
                            source: "document-open-symbolic"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            Layout.alignment: Qt.AlignVCenter
                            opacity: row.hovered ? 0.7 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                    }
                }
            }
        }
    }
}
