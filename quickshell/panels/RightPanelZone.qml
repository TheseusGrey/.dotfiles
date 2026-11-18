import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Reserves the frame's right edge (Rail/expanded panel width).
//
// The visible right panel spans the whole monitor while expanded so that the
// compositor's pointer hit test always finds its surface (see RightPanel.qml),
// which means it cannot carry the exclusive zone itself — an exclusive zone on
// a surface anchored to the bottom-right corner only is ignored by the
// layer-shell rules. This invisible window keeps the reservation instead.
PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    anchors.bottom: true

    implicitWidth: PanelState.rightPanelContext !== ""
        ? Theme.rightPanelExpanded
        : Theme.rightPanelCollapsed
    exclusiveZone: implicitWidth
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-right-zone"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Empty input region: reserve space, never take a click.
    mask: Region {
        item: emptyMask
    }
    Item {
        id: emptyMask
        width: 0
        height: 0
    }
}
