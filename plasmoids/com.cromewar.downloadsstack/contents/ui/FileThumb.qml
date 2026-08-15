import QtQuick
import QtCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "IconTools.js" as IconTools

// Renders a file as a real image thumbnail when it is an image, otherwise as a
// mime-type icon from the current icon theme. For folders, shows the custom icon
// set in Dolphin (read from the folder's .directory) when the option is enabled.
Item {
    id: thumb

    property string fileName: ""
    property var fileUrl: ""
    property bool isDir: false

    readonly property bool isImage: !isDir && IconTools.isImage(fileName)

    // --- custom folder icons (opt-in) ---------------------------------------
    readonly property bool folderIconsEnabled: Plasmoid.configuration.showFolderIcons
    property int _iconTick: 0   // bumped when a .directory read completes

    readonly property string iconSource: {
        _iconTick;                                    // re-eval trigger
        if (!isDir)
            return IconTools.iconName(fileName, isDir);
        if (!folderIconsEnabled)
            return "folder";
        var c = IconTools.cachedFolderIcon(fileUrl);  // depends on fileUrl (reuse-safe)
        return (c && c.length > 0) ? c : "folder";
    }

    // Read the folder's ".directory" once, only when needed and not yet cached.
    // Settings reads INI synchronously; only value() is called, so a folder
    // without a .directory is never written to or created.
    Loader {
        active: thumb.isDir && thumb.folderIconsEnabled
                && IconTools.cachedFolderIcon(thumb.fileUrl) === undefined
        sourceComponent: Settings {
            location: IconTools.directoryFileUrl(thumb.fileUrl)   // QUrl (NOT fileName)
            Component.onCompleted: {
                IconTools.setCachedFolderIcon(thumb.fileUrl,
                    IconTools.resolveIconValue(thumb.fileUrl,
                        value("Desktop Entry/Icon", "")));
                thumb._iconTick++;
            }
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: thumb.isImage ? imageComponent : iconComponent
    }

    Component {
        id: iconComponent
        Kirigami.Icon {
            source: thumb.iconSource
            active: false
        }
    }

    Component {
        id: imageComponent
        Item {
            Image {
                id: img
                anchors.fill: parent
                source: thumb.fileUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                autoTransform: true
                sourceSize.width: 256
                sourceSize.height: 256
                visible: status === Image.Ready
            }
            // Fallback to a generic image icon while loading or on error
            Kirigami.Icon {
                anchors.fill: parent
                source: "image-x-generic"
                visible: img.status !== Image.Ready
                active: false
            }
        }
    }
}
