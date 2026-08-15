import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// One file in the fan: an icon/thumbnail that animates out of the stack,
// shows its name on hover, opens on click, and can be dragged into other apps.
Item {
    id: tile

    property int iconSize: 64
    property string fileName: ""
    property var fileUrl: ""
    property bool isDir: false

    property real labelWidth: 180
    property real gapToLabel: 10
    property bool labelOnLeft: false
    property real tileScale: 1.0

    // Target position (fanned out) vs. collapsed position (inside the stack).
    property real targetX: 0
    property real targetY: 0
    property real collapsedX: 0
    property real collapsedY: 0

    property bool shown: false
    property int stagger: 0
    property bool hovered: false

    signal clicked()
    signal entered()
    signal exited()

    width: iconSize
    height: iconSize
    transformOrigin: Item.Center

    x: shown ? targetX : collapsedX
    y: shown ? targetY : collapsedY
    opacity: shown ? 1.0 : 0.0
    scale: shown ? tileScale : 0.45

    Behavior on x {
        SequentialAnimation {
            PauseAnimation { duration: tile.shown ? tile.stagger : 0 }
            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        }
    }
    Behavior on y {
        SequentialAnimation {
            PauseAnimation { duration: tile.shown ? tile.stagger : 0 }
            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        }
    }
    Behavior on opacity { NumberAnimation { duration: 180 } }
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    // Soft drop shadow under the tile
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: tile.width * 0.16
        color: "transparent"
        visible: !thumb.isImage
    }

    FileThumb {
        id: thumb
        anchors.fill: parent
        fileName: tile.fileName
        fileUrl: tile.fileUrl
        isDir: tile.isDir
        scale: tile.hovered ? 1.1 : 1.0
        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
    }

    // Name label — always visible to the right of the icon (macOS fan style),
    // highlighted when hovered.
    Item {
        id: labelHolder
        visible: tile.fileName.length > 0
        width: tile.labelWidth
        height: pill.height
        x: tile.labelOnLeft ? -(tile.gapToLabel + tile.labelWidth)
                            : (tile.width + tile.gapToLabel)
        anchors.verticalCenter: parent.verticalCenter

        Kirigami.ShadowedRectangle {
            id: pill
            // Keep the pill next to the icon whichever side the labels are on.
            x: tile.labelOnLeft ? (labelHolder.width - width) : 0
            width: Math.min(labelText.implicitWidth + 24, tile.labelWidth)
            height: labelText.implicitHeight + 10
            radius: height / 2
            color: tile.hovered ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            shadow.size: 10
            shadow.color: Qt.rgba(0, 0, 0, 0.35)
            shadow.yOffset: 2
            Behavior on color { ColorAnimation { duration: 120 } }

            PlasmaComponents.Label {
                id: labelText
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                text: tile.fileName
                elide: Text.ElideMiddle
                maximumLineCount: 1
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: tile.labelOnLeft ? Text.AlignRight : Text.AlignLeft
                color: tile.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            }
        }
    }

    // --- Drag-and-drop into other applications ---
    Drag.dragType: Drag.Automatic
    Drag.active: false
    Drag.supportedActions: Qt.CopyAction | Qt.LinkAction
    Drag.proposedAction: Qt.CopyAction
    // text/uri-list is the XDG standard for dropping files onto other apps.
    // Entries are CRLF-terminated per RFC 2483; text/plain is a fallback for
    // targets that only read plain text.
    Drag.mimeData: ({
        "text/uri-list": ("" + tile.fileUrl + "\r\n"),
        "text/plain": ("" + tile.fileUrl)
    })
    Drag.onDragFinished: mouse.dragging = false

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // Don't let an enclosing Flickable (scrollable fan) steal a drag-out.
        preventStealing: true

        property bool dragging: false
        property point pressPos

        readonly property int dragThreshold: (typeof Application !== "undefined" && Application.styleHints)
            ? Application.styleHints.startDragDistance : 10

        onEntered: tile.entered()
        onExited: tile.exited()

        onPressed: (m) => { pressPos = Qt.point(m.x, m.y); }

        onPositionChanged: (m) => {
            if (!pressed || dragging)
                return;
            var dx = m.x - pressPos.x;
            var dy = m.y - pressPos.y;
            if (Math.sqrt(dx * dx + dy * dy) >= dragThreshold) {
                dragging = true;
                thumb.grabToImage(function (result) {
                    tile.Drag.imageSource = result.url;
                    tile.Drag.active = true;
                });
            }
        }

        onReleased: {
            if (!dragging)
                tile.clicked();
        }
    }
}
