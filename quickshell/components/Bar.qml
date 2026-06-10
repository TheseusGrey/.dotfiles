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
    anchors.leftMargin: ConfigTheme.borderThickness + 8
    anchors.rightMargin: ConfigTheme.borderThickness + 8
    spacing: 12

    // === Left section ===
    Item {

    }

    RowLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
          anchors.fill: parent
          color: ConfigTheme.surface2
        }

        Components.StyledText {
            text: {
                const wsId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 0
                const total = Hyprland.workspaces.values.length
                const client = Hyprland.activeToplevel
                const win = client ? client.title : " Desktop"
                const ws = `[ ${wsId}/${total} ]`
                return win !== "" ? `${ws} ${win} ` : ws
            }

            font.weight: Font.Bold

            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
    }

    // === Center section (placeholder for future components) ===
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
          anchors.fill: parent
          color: ConfigTheme.surface2
        }

        Components.StyledText {
            id: clock
            text: Qt.formatDateTime(new Date(), "[ ddd, MMM dd ] [ HH:mm ]")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "[ ddd, MMM dd ] [ HH:mm ]")
            }
        }
    }

    // === Right section (placeholder for future components) ===
    RowLayout {
        Layout.fillHeight: true
        spacing: 8
    }
}
