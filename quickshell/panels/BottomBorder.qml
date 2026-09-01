import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Bottom footer frame — south edge of the TUI frame.
// Lives inside the frame chrome; holds the context-aware key hints.
// Claims its exclusive zone so windows stay clear.
PanelWindow {
    id: root

    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    implicitHeight: Theme.footerHeight
    exclusiveZone: Theme.footerHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-footer"

    // Left/right edges suppressed: the side panels already draw those lines.
    // Bottom edge suppressed: display edge (open frame).
    Tui.TuiPanel {
        anchors.fill: parent
        borderLeft: false
        borderRight: false
        borderBottom: false
    }

    // ─── Content overlay: context-aware key hints ─────────────────────
    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.borderWidth + Theme.panelPadding
        anchors.rightMargin: Theme.borderWidth + Theme.panelPadding
        clip: true

        Widgets.FooterHints {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Tui.TuiMetrics.lineHeight
        }
    }
}