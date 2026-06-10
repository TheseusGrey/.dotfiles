pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components as Components

RowLayout {
    id: root
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 12

    // === Left section ===
    RowLayout {
        Layout.fillHeight: true
        spacing: 8

        Components.StyledText {
            text: {
                const wsId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 0
                const total = Hyprland.workspaces.values.length
                const client = Hyprland.focusedClient
                const win = client ? (client.title !== "" ? client.title : client.class) : ""
                const ws = `[ ${wsId}/${total} ]`
                return win !== "" ? `${ws} ${win}` : ws
            }

            font.pixelSize: 13
            font.weight: Font.Medium

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
    }

    // === Center section (placeholder for future components) ===
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    // === Right section (placeholder for future components) ===
    RowLayout {
        Layout.fillHeight: true
        spacing: 8
    }
}
