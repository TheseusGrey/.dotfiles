import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Floating Finder popup — drops down from below the top panel, centered horizontally.
// Overlay layer, no exclusive zone, click-outside-to-dismiss via HyprlandFocusGrab.
// Animates: fade-in + slide down from top.
PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true

    // Gap between top bar and popup
    margins.top: Theme.topPanelHeight + 12

    // Full-width anchored but content is centered with fixed width
    implicitHeight: finderHeight + 24  // extra space for animation travel
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: PanelState.finderVisible
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-finder"

    readonly property int finderWidth: 560
    readonly property int finderHeight: 460

    // ─── Focus grab: close on click outside ──────────────────────────
    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: PanelState.closeFinder()
    }

    // ─── Centered finder container ───────────────────────────────────
    Rectangle {
        id: container
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.finderWidth
        height: root.finderHeight
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: 0

        // Slide down + fade in animation
        y: root.visible ? 0 : -16
        opacity: root.visible ? 1 : 0

        Behavior on y {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // ─── TUI border frame ────────────────────────────────────────
        // Top border with title
        Text {
            id: topBorder
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            color: Theme.border
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            clip: true

            readonly property real charWidth: borderMetrics.advanceWidth

            text: {
                const availWidth = Math.floor(parent.width / charWidth) - 2;
                if (availWidth < 10) return Theme.boxTopLeft + Theme.boxTopRight;
                const title = " finder ";
                const titleLen = title.length;
                // Center the title in the border
                const leftPad = Math.floor((availWidth - titleLen) / 2);
                const rightPad = availWidth - titleLen - leftPad;
                const prefix = Theme.boxHorizontal.repeat(leftPad);
                const suffix = Theme.boxHorizontal.repeat(rightPad);
                return Theme.boxTopLeft + prefix + " ".repeat(titleLen) + suffix + Theme.boxTopRight;
            }

            TextMetrics {
                id: borderMetrics
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                text: "─"
            }
        }

        // Title overlay (colored, centered)
        Text {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.nord15  // purple accent for title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            text: " finder "
        }

        // Bottom border
        Text {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            color: Theme.border
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            clip: true

            text: {
                const availWidth = Math.floor(parent.width / topBorder.charWidth) - 2;
                if (availWidth < 4) return Theme.boxBottomLeft + Theme.boxBottomRight;
                const fill = Theme.boxHorizontal.repeat(Math.max(0, availWidth));
                return Theme.boxBottomLeft + fill + Theme.boxBottomRight;
            }
        }

        // ─── Finder widget content ───────────────────────────────────
        Widgets.Finder {
            anchors.fill: parent
            anchors.margins: Theme.panelPadding
            anchors.topMargin: topBorder.implicitHeight + 4
            anchors.bottomMargin: topBorder.implicitHeight + 4
        }
    }
}
