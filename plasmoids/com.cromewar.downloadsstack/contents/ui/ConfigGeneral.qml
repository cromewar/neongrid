import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_downloadPath: pathField.text
    property alias cfg_maxItems: maxSpin.value
    property alias cfg_sortBy: sortCombo.currentIndex
    property alias cfg_sortDescending: descCheck.checked
    property alias cfg_showHidden: hiddenCheck.checked

    Kirigami.FormLayout {
        QQC2.TextField {
            id: pathField
            Kirigami.FormData.label: i18n("Downloads folder:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 18
            placeholderText: i18n("Default — your XDG Downloads folder")
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            text: i18n("Leave empty to follow your system Downloads folder, or enter a full path.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.WordWrap
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: maxSpin
            Kirigami.FormData.label: i18n("Files to show:")
            from: 1
            to: 60
        }

        QQC2.ComboBox {
            id: sortCombo
            Kirigami.FormData.label: i18n("Sort by:")
            model: [i18n("Date modified"), i18n("Name"), i18n("Size"), i18n("Type")]
        }

        QQC2.CheckBox {
            id: descCheck
            text: sortCombo.currentIndex === 0 ? i18n("Newest first") : i18n("Descending order")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: hiddenCheck
            Kirigami.FormData.label: i18n("Filter:")
            text: i18n("Show hidden files")
        }
    }
}
