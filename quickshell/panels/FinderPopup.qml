import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Floating Finder popup — drops down from below the top panel, centered horizontally.
// Overlay layer, no exclusive zone, click-outside-to-dismiss via HyprlandFocusGrab.
// Animates: fade-in + slide down from top.
//
// Chrome mirrors the shell's panels: TuiPanel frame (4px rect border + title chip),
// no box-drawing glyphs. A DropShadow trails offset by the same amount Hyprland uses
// for window shadows (decoration.shadow in hyprland.lua) so the popup reads as the
// the same shadow language — keep shadowOffsetX/Y in step with that config.
PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true

    // Gap between top bar and popup
    margins.top: Theme.topPanelHeight + 12

    implicitHeight: finderHeight + 36  // 24 travel + 12 shadow clearance
    exclusionMode: ExclusionMode.Ignore
    visible: PanelState.finderVisible
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-finder"
    // Hold exclusive keyboard focus while visible so the search input keeps
    // the ability to type for as long as the finder is on screen.
    //
    // Do NOT also set `focusable`: that writes OnDemand to the same underlying
    // keyboardFocus property and the two bindings fight over it, which is what
    // made the keyboard grab intermittent.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    readonly property int finderWidth: 560
    readonly property int finderHeight: 460

    // ─── Shadow, kept in sync with hyprland.lua decoration.shadow ────
    //   offset  = { 10, 10 }             (down-right)
    //   sharp   = true                   → hard edge, NO blur
    //   color   = default rgba(0,0,0,0.75)
    readonly property int shadowOffsetX: 10
    readonly property int shadowOffsetY: 10
    readonly property color shadowColor: "#bf000000"

    // ─── Focus grab: close on click outside ──────────────────────────
    // Taking the grab before the layer surface is mapped (or while another
    // panel is still releasing its own grab) gets it cleared immediately by
    // Hyprland. Arm it a beat late, keep re-arming through the mapping window,
    // and only treat a clear as a real outside-click once it has settled.
    property bool grabArmed: false

    onVisibleChanged: {
        grabArmTimer.stop();
        grabSettleTimer.stop();
        grabArmed = false;
        if (visible) {
            grabArmTimer.restart();
        } else if (grab.active) {
            grab.active = false;
        }
    }

    Timer {
        id: grabArmTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!root.visible) return;
            grab.active = true;
            grabSettleTimer.restart();
        }
    }

    Timer {
        id: grabSettleTimer
        interval: 180
        repeat: false
        onTriggered: if (root.visible) root.grabArmed = true;
    }

    HyprlandFocusGrab {
        id: grab
        active: false
        windows: [root]
        onCleared: {
            if (!root.visible) return;
            if (!root.grabArmed) {
                // Transient clear during mapping — re-arm instead of closing.
                grabArmTimer.restart();
                return;
            }
            PanelState.closeFinder();
        }
    }

    // ─── Centered finder stage (shadow + frame move/fade together) ────
    Item {
        id: stage
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.finderWidth
        height: root.finderHeight

        y: root.visible ? 0 : -16
        opacity: root.visible ? 1 : 0

        Behavior on y {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // Shadow source: opaque rect matching the frame; the frame covers it,
        // leaving only the offset blurred shadow visible.
        Rectangle {
            id: shadowBase
            anchors.fill: parent
            color: "black"
        }

        DropShadow {
            anchors.fill: shadowBase
            source: shadowBase
            horizontalOffset: root.shadowOffsetX
            verticalOffset: root.shadowOffsetY
            radius: 0.0
            samples: 1
            color: root.shadowColor
            transparentBorder: true
        }

        // ─── Shell frame (same chrome as the panels/rails) ────────────
        Tui.TuiPanel {
            anchors.fill: parent

            // Header text sits fully inside the border — no border-breaking chip.
            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.itemSpacing

                Tui.TuiText {
                    text: "finder"
                    textColor: Theme.titleColor
                    font.bold: true
                }

                Widgets.Finder {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}