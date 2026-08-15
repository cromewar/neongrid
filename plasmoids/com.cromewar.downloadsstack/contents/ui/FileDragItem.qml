import QtQuick

// A container that makes its content clickable and draggable out to other apps.
// Put visual children inside it; they fill the item and become the drag image.
Item {
    id: dragItem

    property var fileUrl
    property string fileName: ""
    property bool isDir: false

    // The item rendered as the drag pixmap (defaults to the whole thing).
    property Item grabTarget: dragItem

    signal clicked()
    signal entered()
    signal exited()

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool pressed: mouseArea.pressed && !mouseArea.dragging

    default property alias contentData: contentHolder.data
    Item {
        id: contentHolder
        anchors.fill: parent
    }

    Drag.dragType: Drag.Automatic
    Drag.active: false
    Drag.supportedActions: Qt.CopyAction | Qt.LinkAction
    Drag.proposedAction: Qt.CopyAction
    Drag.mimeData: ({
        "text/uri-list": ("" + dragItem.fileUrl + "\r\n"),
        "text/plain": ("" + dragItem.fileUrl)
    })
    Drag.onDragFinished: mouseArea.dragging = false

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property bool dragging: false
        property point pressPos
        readonly property int dragThreshold: (typeof Application !== "undefined" && Application.styleHints)
            ? Application.styleHints.startDragDistance : 10

        onEntered: dragItem.entered()
        onExited: dragItem.exited()
        onPressed: (m) => { pressPos = Qt.point(m.x, m.y); }
        onPositionChanged: (m) => {
            if (!pressed || dragging)
                return;
            var dx = m.x - pressPos.x;
            var dy = m.y - pressPos.y;
            if (Math.sqrt(dx * dx + dy * dy) >= dragThreshold) {
                dragging = true;
                dragItem.grabTarget.grabToImage(function (result) {
                    dragItem.Drag.imageSource = result.url;
                    dragItem.Drag.active = true;
                });
            }
        }
        onReleased: {
            if (!dragging)
                dragItem.clicked();
        }
    }
}
