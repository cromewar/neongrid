import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// macOS-style fan: files arc up from the panel icon, newest nearest. The fan
// grows with the number of files up to a screen-based height cap, then scrolls.
Item {
    id: fan

    property var files: []
    property int extraCount: 0
    property int iconSize: 64
    property string folderPath: ""
    property bool active: false      // drives the fan-out animation
    property bool up: true           // fan climbs up (false = descends)
    property bool labelsLeft: false

    signal openFile(var url)
    signal openFolder()
    signal closeRequested()

    readonly property int n: files.length
    // The fan bows outward as it grows — a few files stack nearly straight, a full
    // stack leans further to the side (like the macOS "heavy" Downloads fan).
    readonly property real curveAmount: iconSize * Math.min(0.45 + n * 0.05, 1.1)
    readonly property int pad: 16
    readonly property int chipH: 30
    readonly property int chipGap: 14
    readonly property real gapToLabel: 10
    readonly property real labelW: iconSize * 3
    // The NEWEST file (nearest the dock) is placed directly over the panel icon.
    // The popup is symmetric and a good bit wider than the visible fan, so wherever
    // the shell puts it — centred on the icon, or clamped to a screen edge — there
    // is always room to slide the icon column back over the icon. `anchorIconX`
    // (set by the host once the popup is on screen, from real screen coordinates)
    // is that icon's x in our own coordinates; until it is known we fall back to the
    // symmetric centre. The fan bows off toward the spacer side; the labels fill the
    // side toward screen-centre; the opposite side is a transparent spacer (and
    // holds the scrollbar).
    readonly property real sideMax: pad + labelW + gapToLabel
    readonly property real iconBandW: curveAmount + iconSize

    // x, in this item's own coordinates, directly above the panel icon (-1 = not yet
    // known). Set by main.qml so the newest file lands over the dock icon regardless
    // of how the shell positioned (or edge-clamped) the popup — i.e. on any screen.
    property real anchorIconX: -1
    readonly property real defColStart: sideMax
    // Bounds that keep the whole fan (labels on one side, the bow on the other)
    // inside the popup even when the anchor is pushed toward an edge.
    readonly property real minColStart: labelsLeft ? sideMax : pad
    readonly property real maxColStart: implicitWidth - pad - iconSize - curveAmount
        - (labelsLeft ? 0 : (gapToLabel + labelW))
    readonly property real iconColStart: (anchorIconX >= 0 && maxColStart > minColStart)
        ? Math.max(minColStart, Math.min(maxColStart, anchorIconX - iconSize / 2))
        : defColStart
    readonly property real gap: iconSize * 1.04

    // ---------------------------------------------------------------- canvas
    // STRUCTURAL RULE: the popup window's size never depends on the number of
    // files. The canvas is a constant-size (per screen) transparent surface and
    // the fan is laid out INSIDE it, anchored to the measured position of the
    // panel icon (anchorIconX / anchorIconY). Because adding or removing files
    // moves pixels inside the window instead of resizing the window, the shell
    // never re-positions or re-clamps the popup, so the fan cannot drift — on
    // any screen size, with any number of items.
    readonly property real canvasH: Math.max(iconSize * 6,
        (Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight : 1000) * 0.82)
    implicitWidth: sideMax * 2 + iconSize
    implicitHeight: canvasH
    // If the shell hands the window a different height than we asked for, lay
    // out against what we actually got.
    readonly property real cH: height > 0 ? height : canvasH

    // y, in this item's own coordinates, of the panel icon's near edge (its top
    // for an upward fan, its bottom for a downward one). NaN = not yet measured
    // (fall back to the canvas edge). Set by main.qml from global screen coords,
    // so the fan hugs the dock wherever the shell actually put the window.
    property real anchorIconY: NaN

    // Gap kept between the fan and the dock.
    readonly property real panelInset: Math.round(iconSize * 0.6)

    // Edge of the content band nearest the panel: just clear of the measured
    // icon, clamped to the canvas so a bad measurement can never push the fan
    // out of the window.
    readonly property real nearEdge: up
        ? (isNaN(anchorIconY) ? cH : Math.max(iconSize, Math.min(anchorIconY, cH))) - panelInset
        : (isNaN(anchorIconY) ? 0 : Math.max(0, Math.min(anchorIconY, cH - iconSize))) + panelInset

    // Room for the chip on the far side, then cap the content to what fits;
    // past that the column scrolls, so any number of files works.
    readonly property real chipSpace: pad + chipH + chipGap
    readonly property real naturalContentH: n > 0 ? ((n - 1) * gap + iconSize) : iconSize
    readonly property real maxContentH: Math.max(iconSize * 2,
        (up ? nearEdge : cH - nearEdge) - chipSpace)
    readonly property bool needsScroll: naturalContentH > maxContentH
    readonly property real contentVisibleH: needsScroll ? maxContentH : naturalContentH
    // Top of the visible content band; everything (files, chip, scrollbar) is
    // placed relative to this, so the whole fan slides as one unit.
    readonly property real contentTop: up ? nearEdge - contentVisibleH : nearEdge

    property int hoveredIndex: -1

    function iconLeft(i) {
        return iconColStart + curveAmount * Math.pow(n > 1 ? i / (n - 1) : 0, 1.5);
    }
    // Vertical position of an icon within the scrolling content (0-based).
    function tileY(i) {
        if (up)
            return naturalContentH - iconSize - i * gap;   // i=0 (newest) at the bottom
        return i * gap;                                     // i=0 (newest) at the top
    }
    function itemScale(i) {
        return 1.0 - 0.10 * (n > 1 ? i / (n - 1) : 0);
    }

    // Keep the newest files in view when the fan (re)opens.
    onActiveChanged: if (active) resetScroll()
    function resetScroll() {
        flick.contentY = up ? Math.max(0, flick.contentHeight - flick.height) : 0;
    }

    // Click on empty space closes the fan
    MouseArea {
        anchors.fill: parent
        onClicked: fan.closeRequested()
    }

    // The scrolling column of files
    Flickable {
        id: flick
        visible: fan.n > 0
        x: 0
        y: fan.contentTop
        width: fan.implicitWidth
        height: fan.contentVisibleH
        contentWidth: width
        contentHeight: fan.naturalContentH
        clip: true
        // A press-drag inside the fan drags a file OUT, so don't flick on drag.
        // Scrolling is handled by the wheel/trackpad handler and the scrollbar.
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        Component.onCompleted: fan.resetScroll()

        Repeater {
            model: fan.files
            delegate: FileTile {
                required property int index
                required property var modelData

                iconSize: fan.iconSize
                fileName: modelData.name
                fileUrl: modelData.url
                isDir: modelData.isDir
                labelWidth: fan.labelW
                gapToLabel: fan.gapToLabel
                labelOnLeft: fan.labelsLeft
                tileScale: fan.itemScale(index)

                targetX: fan.iconLeft(index)
                targetY: fan.tileY(index)
                collapsedX: fan.iconLeft(0)
                collapsedY: fan.tileY(0)

                shown: fan.active
                stagger: Math.min(index, 14) * 24
                hovered: fan.hoveredIndex === index
                z: fan.hoveredIndex === index ? 100 : (fan.n - index)

                onEntered: fan.hoveredIndex = index
                onExited: if (fan.hoveredIndex === index) fan.hoveredIndex = -1
                onClicked: fan.openFile(fileUrl)
            }
        }

    }

    // Standalone scrollbar, placed just outside the icon band on the spacer side
    // (so it never overlaps/clips the icons the way an attached bar would). It
    // sits next to the icons rather than at the far popup edge.
    HoverScrollBar {
        id: sbar
        view: flick
        visible: fan.needsScroll
        height: flick.height
        y: flick.y
        x: fan.labelsLeft ? (fan.iconColStart + fan.iconBandW + Kirigami.Units.smallSpacing)
                          : (fan.iconColStart - Kirigami.Units.smallSpacing - width)
    }

    // Scroll with the mouse wheel or a two-finger trackpad gesture, from anywhere
    // over the fan (a Flickable alone misses the trackpad when the pointer is on a
    // draggable tile).
    WheelHandler {
        enabled: fan.needsScroll
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            var dy = event.pixelDelta.y;
            if (dy === 0)
                dy = event.angleDelta.y / 120 * (fan.gap * 0.7);
            var maxY = flick.contentHeight - flick.height;
            flick.contentY = Math.max(0, Math.min(maxY, flick.contentY - dy));
        }
    }

    // "Open Downloads" / "Show all" chip, pinned at the far end of the fan
    MouseArea {
        id: chip
        z: 50
        width: chipRow.implicitWidth + 24
        height: fan.chipH
        x: Math.max(fan.pad, Math.min(fan.implicitWidth - fan.pad - width,
               fan.iconLeft(fan.up ? fan.n - 1 : 0) + fan.iconSize / 2 - width / 2))
        // The chip hugs the far end of the content band rather than the canvas
        // edge, so it stays next to the files however many there are.
        y: fan.up ? fan.contentTop - fan.chipGap - fan.chipH
                  : fan.contentTop + fan.contentVisibleH + fan.chipGap
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: fan.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        onClicked: fan.openFolder()

        Kirigami.ShadowedRectangle {
            anchors.fill: parent
            radius: height / 2
            color: chip.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            shadow.size: 10
            shadow.color: Qt.rgba(0, 0, 0, 0.3)
            shadow.yOffset: 2
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6
            Kirigami.Icon {
                source: "folder-download"
                width: Kirigami.Units.iconSizes.small
                height: width
                anchors.verticalCenter: parent.verticalCenter
            }
            PlasmaComponents.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: fan.extraCount > 0
                    ? i18n("Show all %1 in Downloads", fan.n + fan.extraCount)
                    : i18n("Open Downloads")
                color: chip.containsMouse ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            }
        }
    }

    PlasmaComponents.Label {
        visible: fan.n === 0
        x: fan.iconColStart + fan.iconSize / 2 - width / 2
        y: fan.up ? fan.nearEdge - fan.iconSize : fan.nearEdge + fan.iconSize - height
        opacity: 0.7
        text: i18n("No recent downloads")
    }
}
