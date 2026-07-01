import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Bottom border — thin decorative line anchored to the bottom of the screen.
// Provides visual grounding without claiming any exclusive zone.
PanelWindow {
    id: root

    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    implicitHeight: 1
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-bottom-border"

    Rectangle {
        anchors.fill: parent
        color: Theme.border
    }
}
