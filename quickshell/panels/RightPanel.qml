import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Right context panel — always visible as a narrow collapsed strip.
// Expands with slide animation when a system icon is clicked.
// Content switches based on PanelState.rightPanelContext.
// Uses HyprlandFocusGrab to auto-close when clicking outside.
PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    anchors.bottom: true

    margins.top: Theme.topPanelHeight

    readonly property bool isExpanded: PanelState.rightPanelContext !== ""

    implicitWidth: isExpanded ? Theme.rightPanelExpanded : Theme.rightPanelCollapsed
    exclusionMode: isExpanded ? ExclusionMode.Normal : ExclusionMode.Ignore
    exclusiveZone: Theme.rightPanelExpanded
    focusable: isExpanded
    color: Theme.bg

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-right"

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Easing.OutCubic
        }
    }

    // ─── Focus grab: close on click outside ──────────────────────────
    HyprlandFocusGrab {
        id: focusGrab
        active: root.isExpanded
        windows: [root]
        onCleared: PanelState.closeRight()
    }

    // ─── Left border ─────────────────────────────────────────────────
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 1
        color: Theme.border
    }

    // ─── Collapsed state: icon hint ──────────────────────────────────
    Item {
        id: collapsedContent
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        visible: !root.isExpanded
        opacity: root.isExpanded ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            // Expand hint glyph
            Tui.TuiText {
                text: "▸"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeLarge
                Layout.alignment: Qt.AlignHCenter
            }

            // Context icon hints (show what's available)
            Tui.TuiText {
                text: "󰕾"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeIcon
                Layout.alignment: Qt.AlignHCenter
            }

            Tui.TuiText {
                text: "󰃟"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeIcon
                Layout.alignment: Qt.AlignHCenter
            }

            Tui.TuiText {
                text: "󰖩"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeIcon
                Layout.alignment: Qt.AlignHCenter
            }

            Tui.TuiText {
                text: "󰂯"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeIcon
                Layout.alignment: Qt.AlignHCenter
            }

            Tui.TuiText {
                text: "⏻"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeIcon
                Layout.alignment: Qt.AlignHCenter
            }

            Tui.TuiText {
                text: "󰂚"
                textColor: NotificationManager.count > 0 ? Theme.warning : Theme.textMuted
                font.pixelSize: Theme.fontSizeIcon
                Layout.alignment: Qt.AlignHCenter
            }

            Tui.TuiText {
                text: "󰍉"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeIcon
                Layout.alignment: Qt.AlignHCenter
            }

            Tui.TuiText {
                text: "⌨"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeIcon
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // ─── Expanded state: full content ────────────────────────────────
    Item {
        id: expandedContent
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        anchors.leftMargin: Theme.panelPadding + 1  // account for left border
        visible: root.isExpanded
        opacity: root.isExpanded ? 1 : 0
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ─── Header: titled box with ┬ connector ────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: headerText.implicitHeight

                Text {
                    id: headerText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    color: Theme.border
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    clip: true

                    text: {
                        const title = " " + contextTitle + " ";
                        const availWidth = Math.floor(parent.width / charWidth);
                        if (availWidth < 6) return Theme.boxTopLeft + Theme.boxTopRight;

                        const connectorPos = 2;
                        const titleLen = title.length;
                        const afterTitle = connectorPos + titleLen;
                        const remaining = Math.max(0, availWidth - afterTitle - 1);
                        const prefix = Theme.boxHorizontal.repeat(connectorPos);
                        const suffix = Theme.boxHorizontal.repeat(remaining);
                        return "┬" + prefix + title + suffix + Theme.boxTopRight;
                    }

                    readonly property real charWidth: headerMetrics.advanceWidth
                    readonly property string contextTitle: {
                        switch (PanelState.rightPanelContext) {
                            case "volume": return "volume";
                            case "brightness": return "brightness";
                            case "wifi": return "wifi";
                            case "bluetooth": return "bluetooth";
                            case "power": return "power";
                            case "notifications": return "notifications";
                            case "finder": return "finder";
                            case "keybinds": return "keybinds";
                            default: return "";
                        }
                    }

                    TextMetrics {
                        id: headerMetrics
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        text: "─"
                    }
                }

                // Title text colored with accent
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: headerText.charWidth * 3.5
                    anchors.top: parent.top
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    text: headerText.contextTitle
                }
            }

            // ─── Content area with side borders ──────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4

                // Left side border (│ characters)
                Column {
                    id: contentLeftBorder
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: headerText.charWidth

                    Repeater {
                        model: Math.max(0, Math.floor(contentLeftBorder.height / headerText.implicitHeight))
                        Text {
                            color: Theme.border
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            text: Theme.boxVertical
                        }
                    }
                }

                // Right side border (│ characters)
                Column {
                    id: contentRightBorder
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: headerText.charWidth

                    Repeater {
                        model: Math.max(0, Math.floor(contentRightBorder.height / headerText.implicitHeight))
                        Text {
                            color: Theme.border
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            text: Theme.boxVertical
                        }
                    }
                }

                // ─── Content switcher ────────────────────────────────
                Item {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: contentLeftBorder.right
                    anchors.right: contentRightBorder.left
                    anchors.leftMargin: Theme.panelPadding
                    anchors.rightMargin: Theme.panelPadding
                    anchors.topMargin: 4

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

                    // Finder / App launcher
                    Widgets.Finder {
                        anchors.fill: parent
                        visible: PanelState.rightPanelContext === "finder"
                    }

                    // Keybind cheat-sheet
                    Widgets.KeybindSheet {
                        anchors.fill: parent
                        visible: PanelState.rightPanelContext === "keybinds"
                    }
                }
            }

            // ─── Bottom border ───────────────────────────────────────
            Text {
                Layout.fillWidth: true
                color: Theme.border
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                clip: true

                text: {
                    const availWidth = Math.floor(parent.width / headerText.charWidth);
                    if (availWidth < 4) return Theme.boxBottomLeft + Theme.boxBottomRight;
                    const fill = Theme.boxHorizontal.repeat(Math.max(0, availWidth - 2));
                    return Theme.boxBottomLeft + fill + Theme.boxBottomRight;
                }
            }
        }
    }
}
