import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// A modern overlay scrollbar: hidden by default, it fades in while you scroll
// or when the pointer is near it, then fades back out. Draggable like any
// window scrollbar.
//
// Two ways to use it:
//   • Attached:   QQC2.ScrollBar.vertical: HoverScrollBar { ... }   (leave `view` unset)
//   • Standalone: HoverScrollBar { view: someFlickable; ... }       (position it yourself)
// Standalone avoids the attached bar reserving/clipping space at the flickable edge.
QQC2.ScrollBar {
    id: control
    property Flickable view: null

    interactive: true
    orientation: Qt.Vertical
    implicitWidth: 14

    // Standalone: mirror the flickable, and drive it while dragging the handle.
    Binding {
        target: control; property: "size"; when: control.view !== null
        value: control.view ? control.view.visibleArea.heightRatio : 1
    }
    Binding {
        target: control; property: "position"; when: control.view !== null && !control.pressed
        value: control.view ? control.view.visibleArea.yPosition : 0
    }

    // Reveal briefly on any position change — covers wheel/trackpad scrolling
    // (which move contentY directly) and dragging the handle.
    property bool scrolling: false
    onPositionChanged: {
        scrolling = true;
        hideTimer.restart();
        if (control.view && control.pressed)
            control.view.contentY = control.view.originY + control.position * control.view.contentHeight;
    }
    Timer { id: hideTimer; interval: 1200; onTriggered: control.scrolling = false }

    readonly property bool reveal: hovered || pressed || scrolling

    contentItem: Item {
        implicitWidth: 14
        Rectangle {
            width: 7
            height: parent.height
            anchors.right: parent.right
            radius: width / 2
            color: control.pressed ? Kirigami.Theme.highlightColor
                : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                          control.hovered ? 0.75 : 0.5)
            opacity: control.reveal ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
    background: Item {
        implicitWidth: 14
        Rectangle {
            width: 7
            height: parent.height
            anchors.right: parent.right
            radius: width / 2
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)
            opacity: control.reveal ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
}
