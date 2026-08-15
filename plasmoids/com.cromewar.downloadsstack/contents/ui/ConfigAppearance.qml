import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_viewMode: viewCombo.currentIndex
    property alias cfg_iconSize: sizeSlider.value
    property alias cfg_gridColumns: colSpin.value
    property alias cfg_compactStyle: styleCombo.currentIndex
    property alias cfg_showBadge: badgeCheck.checked
    property alias cfg_showFolderIcons: folderIconsCheck.checked

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: viewCombo
            Kirigami.FormData.label: i18n("Show downloads as:")
            model: [i18n("Fan"), i18n("Grid"), i18n("List")]
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            text: viewCombo.currentIndex === 0
                ? i18n("A curved stack that fans up from the icon — like the macOS Dock.")
                : viewCombo.currentIndex === 1
                    ? i18n("A tidy grid of thumbnails with names underneath.")
                    : i18n("A compact list, one file per row with its details.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.WordWrap
        }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: i18n("Icon size:")
            QQC2.Slider {
                id: sizeSlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                from: 32
                to: 128
                stepSize: 8
                snapMode: QQC2.Slider.SnapAlways
            }
            QQC2.Label {
                text: i18n("%1 px", sizeSlider.value)
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            }
        }

        QQC2.SpinBox {
            id: colSpin
            Kirigami.FormData.label: i18n("Grid columns:")
            from: 2
            to: 8
            enabled: viewCombo.currentIndex === 1
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            id: styleCombo
            Kirigami.FormData.label: i18n("Panel icon:")
            model: [i18n("Stack of recent files"), i18n("Plain folder icon")]
        }

        QQC2.CheckBox {
            id: badgeCheck
            text: i18n("Show item-count badge")
        }

        QQC2.CheckBox {
            id: folderIconsCheck
            text: i18n("Use custom folder icons")
        }
    }
}
