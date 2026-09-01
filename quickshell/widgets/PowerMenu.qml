import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components as Tui

// Power menu — session actions + system info.
// Style follows the shell's polished conventions:
//   - No tree glyphs on rows; clean icon + label, color only on hover/armed.
//   - Destructive actions (reboot, shutdown) arm on first click and need a
//     second click within 3s to confirm; a countdown shows remaining time.
//   - Non-destructive actions (lock, logout) execute immediately.
//   - Uptime refreshes every 60s.
Item {
    id: root

    // ─── Actions model ───────────────────────────────────────────────
    readonly property var actions: [
        { icon: "", label: "lock", cmd: "loginctl lock-session", color: Theme.accent },
        { icon: "󰗽", label: "logout", cmd: "hyprctl dispatch exit", color: Theme.caution },
        { icon: "󰜉", label: "reboot", cmd: "systemctl reboot", color: Theme.warning },
        { icon: "⏻", label: "shutdown", cmd: "systemctl poweroff", color: Theme.error }
    ]

    // ─── Command executor ────────────────────────────────────────────
    Process {
        id: cmdProc
        running: false
    }

    function execute(cmd) {
        cmdProc.command = ["sh", "-c", cmd];
        cmdProc.running = true;
        PanelState.closeAll();
    }

    // ─── Armed/confirm state ─────────────────────────────────────────
    property int confirmIndex: -1
    property int confirmRemaining: 0

    function arm(index) {
        root.confirmIndex = index;
        root.confirmRemaining = 3;
    }

    // 1s countdown while an action is armed; clears when it expires.
    Timer {
        id: confirmTick
        interval: 1000
        repeat: true
        running: root.confirmIndex >= 0
        onTriggered: {
            root.confirmRemaining -= 1;
            if (root.confirmRemaining <= 0) {
                root.confirmIndex = -1;
                root.confirmRemaining = 0;
            }
        }
    }

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Section label ───────────────────────────────────────────
        Tui.TuiText {
            text: "session"
            textColor: Theme.textMuted
            font.bold: true
            Layout.bottomMargin: Theme.itemSpacing
        }

        // ─── Action list ─────────────────────────────────────────────
        Repeater {
            model: root.actions

            Item {
                id: actionItem
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredHeight: actionRow.implicitHeight + 8

                readonly property bool isConfirming: root.confirmIndex === index
                readonly property bool isDestructive: modelData.cmd.indexOf("reboot") !== -1 ||
                                                      modelData.cmd.indexOf("poweroff") !== -1

                // Armed background: soft error wash from the left edge.
                Rectangle {
                    anchors.fill: parent
                    visible: actionItem.isConfirming
                    color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                }

                // Hover background (plain, not a glyph wall).
                Rectangle {
                    anchors.fill: parent
                    visible: !actionItem.isConfirming && actionMouse.containsMouse
                    color: Theme.bgElevated
                }

                RowLayout {
                    id: actionRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    // Icon
                    Tui.TuiText {
                        text: actionItem.modelData.icon
                        textColor: actionMouse.containsMouse ? actionItem.modelData.color : Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    // Label — shows confirmation prompt while armed.
                    Tui.TuiText {
                        text: actionItem.isConfirming
                            ? "confirm " + actionItem.modelData.label + "?"
                            : actionItem.modelData.label
                        textColor: {
                            if (actionItem.isConfirming) return actionItem.modelData.color;
                            if (actionMouse.containsMouse) return actionItem.modelData.color;
                            return Theme.textPrimary;
                        }
                        font.bold: actionMouse.containsMouse || actionItem.isConfirming
                        Layout.fillWidth: true
                    }

                    // Countdown while armed.
                    Tui.TuiText {
                        visible: actionItem.isConfirming
                        text: "(" + root.confirmRemaining + ")"
                        textColor: Theme.error
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (actionItem.isDestructive) {
                            // First click arms, second click (within 3s) executes.
                            if (root.confirmIndex === actionItem.index) {
                                root.execute(actionItem.modelData.cmd);
                            } else {
                                root.arm(actionItem.index);
                            }
                        } else {
                            root.execute(actionItem.modelData.cmd);
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Theme.itemSpacing * 2 }

        // ─── Rule (dynamic width, like other shell sections) ──────────
        Tui.TuiText {
            Layout.fillWidth: true
            property int charWidth: Math.max(10, Math.floor(width / (Theme.fontSizeSmall * 0.6)))
            text: Theme.boxHorizontal.repeat(charWidth)
            textColor: Theme.border
            font.pixelSize: Theme.fontSizeSmall
        }

        Item { Layout.preferredHeight: Theme.itemSpacing }

        // ─── System info ─────────────────────────────────────────────
        Tui.TuiText {
            text: "system"
            textColor: Theme.textMuted
            font.bold: true
            Layout.bottomMargin: 4
        }

        // Uptime display
        Tui.TuiText {
            id: uptimeText
            text: "󰥔 …"
            textColor: Theme.textPrimary
        }

        Process {
            id: uptimeProc
            command: ["sh", "-c", "uptime -p | sed 's/^up //'"]
            running: true

            stdout: SplitParser {
                onRead: data => {
                    uptimeText.text = "󰥔 " + data.trim();
                }
            }

            onRunningChanged: {
                if (!running) uptimePoll.start();
            }
        }

        Timer {
            id: uptimePoll
            interval: 60000
            repeat: false
            onTriggered: uptimeProc.running = true
        }

        // ─── Spacer ─────────────────────────────────────────────────
        Item { Layout.fillHeight: true }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: "click:run  reboot/shutdown:click again within 3s"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}