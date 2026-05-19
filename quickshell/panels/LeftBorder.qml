import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.theme
import qs.widgets

PanelWindow {
    id: panel
    color: "transparent"

    anchors {
        left: true
        top: true
        bottom: true
    }

    property bool hovered: false
    property bool expanded: hovered || PanelState.activePanel === "left"
    implicitWidth: expanded ? Theme.expandedPanelWidth : Theme.borderThickness

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

    // Collapsed
    Rectangle {
        anchors.fill: parent
        color: Theme.border
        visible: !panel.expanded
    }

    // Expanded: placeholder for Obsidian integration
    Rectangle {
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
            shadowHorizontalOffset: 2
        }

        Text {
            anchors.centerIn: parent
            text: "── obsidian ──\n\n(not yet implemented)"
            color: Theme.fgDim
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
    }
}
