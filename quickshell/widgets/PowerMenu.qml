import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components as Tui

// Power menu — tree-style list of session actions.
// Uses TUI tree glyphs (├── └──) for hierarchy.
// Each item shows an icon + label, highlights on hover.
Item {
    id: root

    // ─── Actions model ───────────────────────────────────────────────
    readonly property var actions: [
        { icon: "", label: "lock", cmd: "loginctl lock-session", color: Theme.accent },
        { icon: "󰗽", label: "logout", cmd: "hyprctl dispatch exit", color: Theme.nord13 },
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

    // ─── Confirmation state ──────────────────────────────────────────
    property int confirmIndex: -1

    Timer {
        id: confirmTimer
        interval: 3000
        repeat: false
        onTriggered: root.confirmIndex = -1
    }

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Warning text ────────────────────────────────────────────
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

                readonly property bool isLast: index === root.actions.length - 1
                readonly property bool isConfirming: root.confirmIndex === index
                readonly property bool isDestructive: modelData.cmd.indexOf("reboot") !== -1 ||
                                                      modelData.cmd.indexOf("poweroff") !== -1

                // Gradient background for confirming destructive actions
                Rectangle {
                    anchors.fill: parent
                    visible: actionItem.isConfirming
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Hover background
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
                    spacing: 8

                    // Tree glyph
                    Tui.TuiText {
                        text: actionItem.isLast ? Theme.treeEnd : Theme.treeBranch
                        textColor: Theme.border
                    }

                    // Icon
                    Tui.TuiText {
                        text: actionItem.modelData.icon
                        textColor: actionMouse.containsMouse ? actionItem.modelData.color : Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    // Label
                    Tui.TuiText {
                        text: actionItem.isConfirming ? actionItem.modelData.label + " (confirm?)" : actionItem.modelData.label
                        textColor: {
                            if (actionItem.isConfirming) return actionItem.modelData.color;
                            if (actionMouse.containsMouse) return actionItem.modelData.color;
                            return Theme.textPrimary;
                        }
                        font.bold: actionMouse.containsMouse || actionItem.isConfirming
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (actionItem.isDestructive) {
                            // Destructive actions require double-click confirmation
                            if (root.confirmIndex === actionItem.index) {
                                root.execute(actionItem.modelData.cmd);
                            } else {
                                root.confirmIndex = actionItem.index;
                                confirmTimer.restart();
                            }
                        } else {
                            root.execute(actionItem.modelData.cmd);
                        }
                    }
                }
            }
        }

        // ─── Separator ───────────────────────────────────────────────
        Item { Layout.preferredHeight: Theme.itemSpacing * 2 }

        Tui.TuiText {
            Layout.fillWidth: true
            text: Theme.boxHorizontal.repeat(40)
            textColor: Theme.border
        }

        Item { Layout.preferredHeight: Theme.itemSpacing }

        // ─── System info ─────────────────────────────────────────────
        Tui.TuiText {
            text: "uptime"
            textColor: Theme.textMuted
            font.bold: true
            Layout.bottomMargin: 4
        }

        // Uptime display
        Tui.TuiText {
            id: uptimeText
            text: "..."
            textColor: Theme.textPrimary
        }

        Process {
            id: uptimeProc
            command: ["sh", "-c", "uptime -p | sed 's/up //'"]
            running: true

            stdout: SplitParser {
                onRead: data => {
                    uptimeText.text = data.trim();
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
            text: "click:select  destructive:double-click"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
