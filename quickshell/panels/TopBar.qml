import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.widgets

PanelWindow {
    id: panel
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    property bool hovered: false
    property bool expanded: hovered || PanelState.activePanel === "top"
    implicitHeight: expanded ? Theme.expandedBarHeight : Theme.borderThickness

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.borderThickness

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onContainsMouseChanged: panel.hovered = containsMouse
        onPressed: (mouse) => mouse.accepted = false
        onReleased: (mouse) => mouse.accepted = false
    }

    // Collapsed state: thin accent line
    Rectangle {
        anchors.fill: parent
        color: Theme.border
        visible: !panel.expanded
    }

    // Expanded state: full bar
    Rectangle {
        id: expandedRect
        anchors.fill: parent
        color: Theme.bg
        visible: panel.expanded
        border.color: Theme.border
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 0.3
            shadowVerticalOffset: 2
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 16

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }

            // Separator
            Rectangle {
                width: 1; Layout.fillHeight: true
                Layout.topMargin: 8; Layout.bottomMargin: 8
                color: Theme.border
            }

            ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            // Separator
            Rectangle {
                width: 1; Layout.fillHeight: true
                Layout.topMargin: 8; Layout.bottomMargin: 8
                color: Theme.border
            }

            StatusIcons {
                Layout.alignment: Qt.AlignVCenter
            }

            // Separator
            Rectangle {
                width: 1; Layout.fillHeight: true
                Layout.topMargin: 8; Layout.bottomMargin: 8
                color: Theme.border
            }

            Clock {
                Layout.alignment: Qt.AlignVCenter
            }

            // Separator
            Rectangle {
                width: 1; Layout.fillHeight: true
                Layout.topMargin: 8; Layout.bottomMargin: 8
                color: Theme.border
            }

            PowerButton {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
    }
}
