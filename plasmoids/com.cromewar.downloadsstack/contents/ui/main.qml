import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.folderlistmodel
import Qt.labs.platform as Platform
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "IconTools.js" as IconTools

PlasmoidItem {
    id: root

    // ----------------------------------------------------------------- data
    readonly property string resolvedPath: computePath(Plasmoid.configuration.downloadPath)
    property var fileItems: []       // [{ url, name, isDir }], newest first
    property int extraCount: 0       // files beyond the fan limit
    property Item compactItem: null

    // Fan opens away from the panel: down if the panel is on the top edge, up otherwise.
    readonly property bool openUp: Plasmoid.location !== PlasmaCore.Types.TopEdge

    // Open/close state, separated from dialog visibility so we can animate the collapse.
    property bool fanOpen: false
    property bool fanShown: false
    property bool fanLabelsLeft: false   // computed each time the fan opens
    property double lastHideMs: 0

    preferredRepresentation: compactRepresentation
    Plasmoid.icon: "folder-download"

    toolTipMainText: fileItems.length > 0 ? fileItems[0].name : i18n("Downloads")
    toolTipSubText: (fileItems.length + extraCount) > 0
        ? i18n("%1 in Downloads — click to fan out", fileItems.length + extraCount)
        : i18n("No recent downloads")

    function computePath(cfg) {
        var p = (cfg && ("" + cfg).length > 0)
            ? ("" + cfg)
            : ("" + Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation));
        return p.replace(/^file:\/\//, "");
    }

    // Map the "sort by" config (0 date, 1 name, 2 size, 3 type) to the model.
    readonly property int folderSortField: {
        switch (Plasmoid.configuration.sortBy) {
        case 1: return FolderListModel.Name;
        case 2: return FolderListModel.Size;
        case 3: return FolderListModel.Type;
        default: return FolderListModel.Time;
        }
    }
    // FolderListModel sorts Time the opposite way from the others, so invert it.
    readonly property bool folderSortReversed: {
        var desc = Plasmoid.configuration.sortDescending;
        return Plasmoid.configuration.sortBy === 0 ? !desc : desc;
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + root.resolvedPath
        showDirs: true
        showDotAndDotDot: false
        showHidden: Plasmoid.configuration.showHidden
        sortField: root.folderSortField
        sortReversed: root.folderSortReversed
        onCountChanged: root.rebuild()
        onStatusChanged: if (status === FolderListModel.Ready) root.rebuild()
    }

    function rebuild() {
        var arr = [];
        var cnt = folderModel.count;
        var lim = Math.min(cnt, Plasmoid.configuration.maxItems);
        for (var i = 0; i < lim; ++i) {
            var url = folderModel.get(i, "fileUrl");
            arr.push({
                url: (url === undefined || url === null) ? "" : ("" + url),
                name: folderModel.get(i, "fileName"),
                isDir: folderModel.get(i, "fileIsDir") === true
            });
        }
        root.fileItems = arr;
        root.extraCount = Math.max(0, cnt - lim);
    }

    Connections {
        target: Plasmoid.configuration
        function onMaxItemsChanged() { root.rebuild(); }
    }

    // ------------------------------------------------------------- open/close
    function toggleFan() {
        // Ignore the click that just dismissed the dialog (deactivate + click race).
        if (Date.now() - root.lastHideMs < 250)
            return;
        root.fanOpen = !root.fanOpen;
    }
    function closeFan() { root.fanOpen = false; }
    function openAndClose(url) { Qt.openUrlExternally(url); closeFan(); }
    function openFolderAndClose() { Qt.openUrlExternally("file://" + resolvedPath); closeFan(); }

    onFanOpenChanged: {
        if (fanOpen) {
            // Re-read custom folder icons each time the popup opens, so a folder's
            // icon changed in Dolphin shows up without a plasmoid restart.
            IconTools.clearFolderIconCache();
            // Initial guess for the label side from the widget's position within its
            // panel window (reliable on Wayland even before the popup is on screen);
            // alignFan() refines it from real screen coordinates once the popup opens.
            if (compactItem && compactItem.windowFraction !== undefined)
                root.fanLabelsLeft = compactItem.windowFraction() > 0.5;
            fanDialog.visible = true;
            Qt.callLater(function () { root.fanShown = true; root.alignFan(); });
        } else {
            root.fanShown = false;
            if (viewLoader.item && viewLoader.item.anchorIconX !== undefined)
                viewLoader.item.anchorIconX = -1;   // recompute fresh on next open
            if (viewLoader.item && viewLoader.item.anchorIconY !== undefined)
                viewLoader.item.anchorIconY = NaN;
            collapseTimer.restart();
        }
    }

    // Slide the fan so its newest file sits directly over the panel icon, whatever
    // the shell did with the popup (centre it, or clamp it to a screen edge). Uses
    // real global screen coordinates — the popup's origin and the panel icon's
    // centre — so it is correct on any screen size and any widget position, not just
    // the one the fan happened to be tuned on. A no-op when the shell already centred
    // the popup on the icon. Only the Fan view exposes anchorIconX; Grid/List ignore.
    function alignFan() {
        if (!fanOpen || !compactItem)
            return;
        var item = viewLoader.item;
        if (!item || item.anchorIconX === undefined)
            return;
        var gIcon = compactItem.mapToGlobal(compactItem.width / 2, compactItem.height / 2);
        var gOrigin = item.mapToGlobal(0, 0);
        if (!gIcon || !gOrigin)
            return;
        item.anchorIconX = gIcon.x - gOrigin.x;         // panel icon's x in fan coords
        // Vertical anchor: the icon's near edge (top for an upward fan, bottom
        // for a downward one) in fan coords, so the fan hugs the dock wherever
        // the shell actually put the popup window.
        if (item.anchorIconY !== undefined) {
            var gEdge = root.openUp
                ? compactItem.mapToGlobal(compactItem.width / 2, 0)
                : compactItem.mapToGlobal(compactItem.width / 2, compactItem.height);
            item.anchorIconY = gEdge.y - gOrigin.y;
        }
        // Labels fill the side toward screen-centre — decided from the icon's true
        // position on its screen (works for full-width panels and floating docks
        // alike). Screen is an attached property, so read it in our own scope —
        // root lives in the same panel window as the icon.
        if (Screen.width > 0)
            root.fanLabelsLeft = gIcon.x > (Screen.virtualX + Screen.width / 2);
    }

    Timer {
        id: collapseTimer
        interval: 300
        onTriggered: fanDialog.visible = false
    }

    Connections {
        target: fanDialog
        function onVisibleChanged() {
            if (!fanDialog.visible) {
                root.lastHideMs = Date.now();
                root.fanOpen = false;
                root.fanShown = false;
            }
        }
        // The shell positions/edge-clamps the popup asynchronously (layer-shell
        // configure), so re-align whenever the window settles at (or moves to)
        // a new spot — any axis, any dimension.
        function onXChanged() { if (root.fanOpen) Qt.callLater(root.alignFan); }
        function onYChanged() { if (root.fanOpen) Qt.callLater(root.alignFan); }
        function onWidthChanged() { if (root.fanOpen) Qt.callLater(root.alignFan); }
        function onHeightChanged() { if (root.fanOpen) Qt.callLater(root.alignFan); }
    }

    // ------------------------------------------------ compact representation
    compactRepresentation: Item {
        id: compact

        readonly property real s: Math.min(width, height)
        readonly property bool hasFiles: root.fileItems.length > 0
        readonly property bool stackStyle: Plasmoid.configuration.compactStyle === 0
        readonly property bool showStack: stackStyle && hasFiles

        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium

        // Match the proven Folder View idiom: only minimum sizes; the shell
        // stretches the item to fill the applet cell.
        Layout.minimumWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
            ? compact.height : Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical
            ? compact.width : Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.large
        Layout.preferredHeight: Kirigami.Units.iconSizes.large

        Component.onCompleted: root.compactItem = compact

        // Where this widget sits within its panel window, 0 (left) .. 1 (right).
        // Uses window-relative coords, which are reliable under Wayland.
        function windowFraction() {
            var w = Window.width;
            if (!w || w <= 0)
                return 0.5;
            var cx = compact.mapToItem(null, compact.width / 2, 0).x;
            return cx / w;
        }

        // "Pile" of papers behind the front tile
        Repeater {
            model: compact.showStack ? 2 : 0
            delegate: Kirigami.ShadowedRectangle {
                required property int index
                width: compact.s * 0.72
                height: width
                radius: width * 0.16
                color: Kirigami.Theme.backgroundColor
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (index === 0 ? -1 : 1) * compact.s * 0.07
                anchors.verticalCenterOffset: -(index + 1) * compact.s * 0.05
                opacity: 0.55 - index * 0.18
                rotation: index === 0 ? -7 : 7
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                shadow.size: compact.s * 0.1
                shadow.color: Qt.rgba(0, 0, 0, 0.3)
                shadow.yOffset: 1
            }
        }

        // Front: newest file's thumbnail (Stack style), else the folder icon
        Loader {
            anchors.centerIn: parent
            width: compact.s * (compact.showStack ? 0.8 : 1.0)
            height: width
            sourceComponent: compact.showStack ? frontThumb : folderIcon
        }
        Component {
            id: folderIcon
            Kirigami.Icon { source: "folder-download"; active: compactMouse.containsMouse }
        }
        Component {
            id: frontThumb
            Kirigami.ShadowedRectangle {
                radius: width * 0.16
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
                shadow.size: width * 0.12
                shadow.color: Qt.rgba(0, 0, 0, 0.35)
                shadow.yOffset: 1
                FileThumb {
                    anchors.fill: parent
                    anchors.margins: parent.width * 0.1
                    fileName: root.fileItems.length > 0 ? root.fileItems[0].name : ""
                    fileUrl: root.fileItems.length > 0 ? root.fileItems[0].url : ""
                    isDir: root.fileItems.length > 0 ? root.fileItems[0].isDir : false
                }
            }
        }

        // Count badge
        Rectangle {
            id: badge
            visible: Plasmoid.configuration.showBadge && (root.fileItems.length + root.extraCount) > 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(compact.s * 0.4)
            width: Math.max(height, badgeLabel.implicitWidth + 6)
            radius: height / 2
            color: Kirigami.Theme.highlightColor
            border.width: 1
            border.color: Kirigami.Theme.backgroundColor
            PlasmaComponents.Label {
                id: badgeLabel
                anchors.centerIn: parent
                text: root.fileItems.length + root.extraCount
                color: Kirigami.Theme.highlightedTextColor
                font.pixelSize: Math.round(compact.s * 0.26)
                font.bold: true
            }
        }

        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleFan()
        }
    }

    // Plasma requires a full representation to exist for the compact one to
    // render. The fan itself is shown in a custom frameless dialog (below) for
    // the floating macOS look, so this is only ever seen if the widget is
    // placed on the desktop rather than in a panel.
    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.minimumHeight: Kirigami.Units.gridUnit * 9
        spacing: Kirigami.Units.largeSpacing

        Item { Layout.fillHeight: true }
        Kirigami.Icon {
            source: "folder-download"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.enormous
            Layout.preferredHeight: Kirigami.Units.iconSizes.enormous
        }
        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: (root.fileItems.length + root.extraCount) > 0
                ? i18n("%1 recent download(s)", root.fileItems.length + root.extraCount)
                : i18n("No recent downloads")
        }
        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: i18n("Add this widget to a panel and click it to fan out your latest downloads.")
        }
        PlasmaComponents.Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "folder-open"
            text: i18n("Open Downloads folder")
            onClicked: Qt.openUrlExternally("file://" + root.resolvedPath)
        }
        Item { Layout.fillHeight: true }
    }

    // ----------------------------------------------------------- the popup
    PlasmaCore.Dialog {
        id: fanDialog
        visualParent: root.compactItem
        location: Plasmoid.location
        // AppletPopup positions relative to the icon and, unlike PopupMenu,
        // lets items be dragged out into other windows without closing.
        type: PlasmaCore.Dialog.AppletPopup
        hideOnWindowDeactivate: true
        // Every view draws its own surface (the fan floats; grid and list use a
        // self-drawn card), so the dialog itself is always frameless. This keeps
        // the visible content hugging its size even when the shell hands the
        // popup window a larger, stale height.
        backgroundHints: PlasmaCore.Dialog.NoBackground

        mainItem: Loader {
            id: viewLoader
            sourceComponent: {
                switch (Plasmoid.configuration.viewMode) {
                case 1: return gridComponent;
                case 2: return listComponent;
                default: return fanComponent;
                }
            }
        }
    }

    Component {
        id: fanComponent
        FanMode {
            files: root.fileItems
            extraCount: root.extraCount
            iconSize: Plasmoid.configuration.iconSize
            folderPath: root.resolvedPath
            active: root.fanShown
            up: root.openUp
            labelsLeft: root.fanLabelsLeft
            onOpenFile: (url) => root.openAndClose(url)
            onOpenFolder: root.openFolderAndClose()
            onCloseRequested: root.closeFan()
        }
    }
    Component {
        id: gridComponent
        GridMode {
            files: root.fileItems
            extraCount: root.extraCount
            iconSize: Plasmoid.configuration.iconSize
            columns: Plasmoid.configuration.gridColumns
            folderPath: root.resolvedPath
            active: root.fanShown
            up: root.openUp
            onOpenFile: (url) => root.openAndClose(url)
            onOpenFolder: root.openFolderAndClose()
            onCloseRequested: root.closeFan()
        }
    }
    Component {
        id: listComponent
        ListMode {
            files: root.fileItems
            extraCount: root.extraCount
            iconSize: Plasmoid.configuration.iconSize
            folderPath: root.resolvedPath
            active: root.fanShown
            up: root.openUp
            onOpenFile: (url) => root.openAndClose(url)
            onOpenFolder: root.openFolderAndClose()
            onCloseRequested: root.closeFan()
        }
    }
}
