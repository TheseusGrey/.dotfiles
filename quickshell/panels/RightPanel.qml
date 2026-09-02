import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Right context panel — east edge of the TUI frame.
// Always visible as a narrow collapsed strip; expands with slide animation
// when a status icon is clicked. Content switches based on rightPanelContext.
// The panel shows an inside-the-border header text (context title) when expanded,
// mirroring the finder popup header style — no border-breaking title chip.
// Uses HyprlandFocusGrab to auto-close when clicking outside.
PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    anchors.bottom: true

    readonly property bool isExpanded: PanelState.rightPanelContext !== ""

    readonly property string contextTitle: {
        switch (PanelState.rightPanelContext) {
            case "volume": return "volume";
            case "brightness": return "brightness";
            case "wifi": return "network";
            case "bluetooth": return "bluetooth";
            case "power": return "power";
            case "notifications": return "notifications";
            case "keybinds": return "keybinds";
            case "menu": return "menu";
            case "theme": return "theme";
            default: return "";
        }
    }

    implicitWidth: isExpanded ? Theme.rightPanelExpanded : Theme.rightPanelCollapsed
    exclusiveZone: isExpanded ? Theme.rightPanelExpanded : Theme.rightPanelCollapsed
    focusable: isExpanded
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-right"

    // No width animation: snap open/closed (same reason as the left panel —
    // prevents the footer strip from visually "playing catch-up" at the
    // shared bottom corner mid-slide). No Behavior on implicitWidth.

    // ─── Focus grab: close on click outside ──────────────────────────
    // Keep the grab active whenever the panel is expanded (don't toggle it off
    // during theme work — releasing the grab to "protect" it fires onCleared
    // and closes the panel). Instead, suppress the close while a theme
    // operation is running (themeProcessRunning, set synchronously on click and
    // held through a short grace period). A genuine outside-click while no
    // theme op is running still closes normally.
    HyprlandFocusGrab {
        id: focusGrab
        active: root.isExpanded
        windows: [root]
        onCleared: {
            if (PanelState.themeProcessRunning) return;
            PanelState.closeRight();
        }
    }

    // ─── Frame chrome (bg + blocky border) ─────────────────────────────
    // Top edge suppressed: the top bar already draws the line at the corner.
    // Right edge suppressed: display edge (open frame), bottom edge is covered
    // by the opaque footer strip anyway.
    Tui.TuiPanel {
        anchors.fill: parent
        borderTop: false
        borderRight: false
        borderBottom: false
    }

    // ─── Collapsed state: icon hint strip ────────────────────────────
    Tui.TuiRail {
        visible: !root.isExpanded
        anchors.fill: parent
        anchors.margins: Theme.borderWidth
        model: collapsedIconModel
        onActivated: item => {
            if (typeof item === "object" && item.target !== undefined) {
                PanelState.openRight(item.target);
            }
        }
    }

    // ─── Expanded state: full content ────────────────────────────────
    Item {
        id: expandedContent
        visible: root.isExpanded
        anchors.fill: parent
        anchors.leftMargin: Theme.borderWidth + Theme.panelPadding
        anchors.rightMargin: Theme.borderWidth + Theme.panelPadding
        anchors.bottomMargin: Theme.borderWidth + Theme.panelPadding
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: Theme.borderWidth + Theme.panelPadding
            spacing: Theme.itemSpacing

            // ─── Header: title + (back to menu) button ────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.itemSpacing

                Tui.TuiText {
                    text: root.contextTitle
                    textColor: Theme.titleColor
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                }

                Tui.TuiButton {
                    text: "◀ back"
                    variant: "body"
                    width: Tui.TuiMetrics.cellWidth * 8
                    height: Tui.TuiMetrics.lineHeight + Theme.panelPadding
                    visible: PanelState.rightPanelCanGoBack
                    onClicked: PanelState.goBackToMenu()
                }
            }

            // ─── Context content ─────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Volume control
                Widgets.VolumeControl {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "volume"
                }

                // Brightness control
                Widgets.BrightnessControl {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "brightness"
                }

                // WiFi panel
                Widgets.WiFiPanel {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "wifi"
                }

                // Bluetooth panel
                Widgets.BluetoothPanel {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "bluetooth"
                }

                // Power menu
                Widgets.PowerMenu {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "power"
                }

                // Notifications
                Widgets.NotificationList {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "notifications"
                }

                // Keybind cheat-sheet
                Widgets.KeybindSheet {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "keybinds"
                }

                // Context menu (titled list of every panel)
                Widgets.ContextMenu {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "menu"
                }

                // Theme switcher
                Widgets.ThemePanel {
                    anchors.fill: parent
                    visible: PanelState.rightPanelContext === "theme"
                }
            }
        }
    }

    // Model for the collapsed strip icons: click opens the matching context.
    readonly property var collapsedIconModel: [
        { glyph: "󰕾", active: PanelState.rightPanelContext === "volume", target: "volume" },
        { glyph: "󰃟", active: PanelState.rightPanelContext === "brightness", target: "brightness" },
        { glyph: "󰖩", active: PanelState.rightPanelContext === "wifi", target: "wifi" },
        { glyph: "󰂯", active: PanelState.rightPanelContext === "bluetooth", target: "bluetooth" },
        { glyph: "󰂚", active: PanelState.rightPanelContext === "notifications", target: "notifications" },
        { glyph: "⌨", active: PanelState.rightPanelContext === "keybinds", target: "keybinds" },
        { glyph: "◐", active: PanelState.rightPanelContext === "theme", target: "theme" },
        { glyph: "⏻", active: PanelState.rightPanelContext === "power", target: "power" }
    ]
}
