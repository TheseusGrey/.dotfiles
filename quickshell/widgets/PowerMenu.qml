import QtQuick
import QtQuick.Layouts
import Quickshell
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
        { icon: "󰌾", label: "lock", shortcut: "l", cmd: "loginctl lock-session", color: Theme.accent },
        { icon: "󰗽", label: "logout", shortcut: "o", cmd: "hyprctl dispatch exit", color: Theme.caution },
        { icon: "󰜉", label: "reboot", shortcut: "r", cmd: "systemctl reboot", color: Theme.warning },
        { icon: "󰐥", label: "shutdown", shortcut: "s", cmd: "systemctl poweroff", color: Theme.error }
    ]

    // ─── Command executor ────────────────────────────────────────────
    // The panel widget is destroyed by closeAll(), so this cannot use a
    // Process owned by the widget: the command would be killed with it.
    // execDetached double-forks, letting systemctl finish after teardown.
    function execute(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
        PanelState.closeAll();
    }

    function isDestructive(cmd) {
        return cmd.indexOf("reboot") !== -1 || cmd.indexOf("poweroff") !== -1;
    }

    // ─── Armed/confirm state ─────────────────────────────────────────
    property int confirmIndex: -1
    property int confirmRemaining: 0
    property int selectedIndex: 0

    function arm(index) {
        root.confirmIndex = index;
        root.confirmRemaining = 3;
    }

    function triggerAction(index) {
        if (index < 0 || index >= root.actions.length) return;
        const action = root.actions[index];
        if (root.isDestructive(action.cmd)) {
            // First press arms, second press within 3s executes.
            if (root.confirmIndex === index) root.execute(action.cmd);
            else root.arm(index);
        } else {
            root.execute(action.cmd);
        }
    }

    function moveSelection(delta) {
        root.selectedIndex = (root.selectedIndex + delta + root.actions.length) % root.actions.length;
    }

    function activateSelected() {
        root.triggerAction(root.selectedIndex);
    }

    function triggerByLabel(label) {
        for (let i = 0; i < root.actions.length; i++) {
            if (root.actions[i].label === label) {
                root.selectedIndex = i;
                root.triggerAction(i);
                return true;
            }
        }
        return false;
    }

    function handlePanelAction(action, arg) {
        switch (action) {
            case "next":     root.moveSelection(1); return true;
            case "prev":     root.moveSelection(-1); return true;
            case "activate": root.activateSelected(); return true;
            case "lock":     return root.triggerByLabel("lock");
            case "logout":   return root.triggerByLabel("logout");
            case "reboot":   return root.triggerByLabel("reboot");
            case "shutdown": return root.triggerByLabel("shutdown");
        }
        return false;
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
                readonly property bool isSelected: root.selectedIndex === index
                readonly property bool isDestructive: modelData.cmd.indexOf("reboot") !== -1 ||
                                                      modelData.cmd.indexOf("poweroff") !== -1

                // Row background: armed wash wins, then the keyboard cursor,
                // then hover.
                Rectangle {
                    anchors.fill: parent
                    visible: actionItem.isConfirming || actionItem.isSelected || actionMouse.containsMouse
                    color: actionItem.isConfirming
                        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                        : actionItem.isSelected ? Theme.bgHover : Theme.bgElevated
                }

                // Left cursor notch.
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 2
                    color: actionItem.isSelected ? Theme.accent : "transparent"
                }

                RowLayout {
                    id: actionRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    readonly property bool isActive: actionItem.isSelected || actionMouse.containsMouse

                    // Icon
                    Tui.TuiText {
                        text: actionItem.modelData.icon
                        textColor: actionRow.isActive ? actionItem.modelData.color : Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    // Label — shows confirmation prompt while armed.
                    Tui.TuiText {
                        text: actionItem.isConfirming
                            ? "confirm " + actionItem.modelData.label + "?"
                            : actionItem.modelData.label
                        textColor: {
                            if (actionItem.isConfirming) return actionItem.modelData.color;
                            if (actionRow.isActive) return actionItem.modelData.color;
                            return Theme.textPrimary;
                        }
                        font.bold: actionRow.isActive || actionItem.isConfirming
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

                    // Key hint chip.
                    Tui.TuiText {
                        visible: !actionItem.isConfirming
                        text: "[" + actionItem.modelData.shortcut + "]"
                        textColor: actionRow.isActive ? actionItem.modelData.color : Theme.accent
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
                        root.selectedIndex = actionItem.index;
                        root.triggerAction(actionItem.index);
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
            Layout.fillWidth: true
            text: root.confirmIndex >= 0
                ? "press again to confirm  esc cancel"
                : "j/k select  enter run  l/o/r/s direct"
            textColor: root.confirmIndex >= 0 ? Theme.error : Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
        }
    }
}