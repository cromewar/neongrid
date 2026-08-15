/*
    SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2026 NeonGrid

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.clock as PlasmaClock
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root
    spacing: 4

    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    readonly property color neon: "#39ff14"
    readonly property color muted: "#c6d0cb"

    PlasmaComponents3.Label {
        text: Qt.formatTime(timeSource.dateTime, "HH:mm")
        textFormat: Text.PlainText
        color: root.neon
        style: root.softwareRendering ? Text.Outline : Text.Normal
        styleColor: root.softwareRendering ? "#0a0e0f" : "transparent"
        font.family: "Orbitron"
        font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 7.2)
        font.weight: Font.DemiBold
        font.letterSpacing: 4
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignHCenter
    }
    PlasmaComponents3.Label {
        text: Qt.formatDate(timeSource.dateTime, Qt.locale(), Locale.LongFormat)
        textFormat: Text.PlainText
        color: root.muted
        style: root.softwareRendering ? Text.Outline : Text.Normal
        styleColor: root.softwareRendering ? "#0a0e0f" : "transparent"
        font.family: "Rajdhani"
        font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.2)
        font.weight: Font.DemiBold
        font.letterSpacing: 1.5
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignHCenter
    }

    PlasmaClock.Clock {
        id: timeSource
        trackSeconds: false
    }
}
