import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components as Tui

// OSD Overlay — transient popup for volume/brightness changes.
// Centered on screen, floats above everything, auto-fades after 1.5s.
// Triggered via IPC: qs ipc call shell osdVolume 0.75
//
// Visual:
//   ╭─ 󰕾 volume ──────────────╮
//   │  ▌▌▌▌▌▌▌▌░░  75%         │
//   ╰──────────────────────────╯
PanelWindow {
    id: root

    // Centered on screen (no anchors = floating, but we need layer shell)
    // Use all four anchors with margins to center
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-osd"

    // Empty mask so clicks pass through
    mask: Region {
        item: emptyMask
    }
    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    // ─── State ───────────────────────────────────────────────────────
    property string osdType: ""      // "volume" or "brightness"
    property real osdValue: 0.0      // 0.0 to 1.0
    property bool osdMuted: false    // volume muted state

    // Listen to PanelState OSD signals
    Connections {
        target: PanelState
        function onOsdRequested(type, value, muted) {
            root.show(type, value, muted);
        }
    }

    // Public function to show OSD
    function show(type: string, value: real, muted: bool) {
        root.osdType = type;
        root.osdValue = Math.max(0, Math.min(1, value));
        root.osdMuted = muted || false;
        osdBox.opacity = 1;
        hideTimer.restart();
    }

    // Auto-hide after 1.5s
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osdBox.opacity = 0
    }

    // ─── Centered OSD box ────────────────────────────────────────────
    Rectangle {
        id: osdBox
        anchors.centerIn: parent
        width: 280
        height: 64
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: 2
        opacity: 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.panelPadding
            spacing: 4

            // ─── Header: icon + type name ────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: {
                        if (root.osdType === "volume") {
                            if (root.osdMuted) return "󰖁";
                            if (root.osdValue > 0.66) return "󰕾";
                            if (root.osdValue > 0.33) return "󰖀";
                            return "󰕿";
                        }
                        if (root.osdType === "brightness") {
                            if (root.osdValue > 0.66) return "󰃠";
                            if (root.osdValue > 0.33) return "󰃟";
                            return "󰃞";
                        }
                        return "?";
                    }
                    color: root.osdType === "volume" ? Theme.nord7 : Theme.nord13
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: root.osdType
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    verticalAlignment: Text.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.osdMuted ? "muted" : Math.round(root.osdValue * 100) + "%"
                    color: root.osdMuted ? Theme.textMuted : Theme.textBright
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // ─── Progress bar (gradient fill) ─────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: osdBarText.implicitHeight

                // Empty track background
                Text {
                    id: osdBarText
                    anchors.fill: parent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    verticalAlignment: Text.AlignVCenter
                    textFormat: Text.RichText
                    text: {
                        const barLen = 28;
                        const clamped = root.osdMuted ? 0 : Math.max(0, Math.min(1, root.osdValue));
                        const filled = Math.round(clamped * barLen);
                        const empty = barLen - filled;
                        let result = "";
                        if (filled > 0) {
                            result += `<span style="color:${root.osdMuted ? Theme.textMuted : Theme.border}">`;
                            result += Theme.blockHalf.repeat(filled);
                            result += "</span>";
                        }
                        if (empty > 0) {
                            result += `<span style="color:${Theme.border}">`;
                            result += Theme.blockEmpty.repeat(empty);
                            result += "</span>";
                        }
                        return result;
                    }
                }

                // Gradient overlay on the filled portion
                Rectangle {
                    visible: !root.osdMuted && root.osdValue > 0
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0, Math.min(1, root.osdValue))
                    opacity: 0.85

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: root.osdType === "volume" ? Theme.nord10 : Theme.nord12
                        }
                        GradientStop {
                            position: 1.0
                            color: root.osdType === "volume" ? Theme.nord7 : Theme.nord13
                        }
                    }
                }
            }
        }
    }
}
