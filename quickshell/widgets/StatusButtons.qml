import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components as Tui

// Status buttons row — the condensed top-bar right cluster.
// Confirmed set: volume readout (icon + %), network state icon (WiFi or
// Ethernet), notification bell, and one context-menu button that opens the
// right panel's "menu" list of every panel.
// Clicking any item opens that context in the right panel.
RowLayout {
    id: root
    spacing: 4

    // ─── Live default-sink volume ────────────────────────────────────
    property real volume: 0
    property bool volumeMuted: false

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                root.volumeMuted = data.indexOf("[MUTED]") !== -1;
                const match = data.match(/Volume:\s+([\d.]+)/);
                if (match) root.volume = parseFloat(match[1]);
            }
        }

        onRunningChanged: {
            if (!running) volPollTimer.start();
        }
    }

    Timer {
        id: volPollTimer
        interval: 2000
        repeat: false
        onTriggered: volProc.running = true
    }

    // ─── Wired/wireless detection ────────────────────────────────────
    property bool hasEthernet: false

    Process {
        id: netCheckProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                netCheckProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                root.hasEthernet = netCheckProc.buffer.indexOf("ethernet:connected") !== -1;
                netCheckProc.buffer = "";
                netCheckTimer.start();
            }
        }
    }

    Timer {
        id: netCheckTimer
        interval: 5000
        repeat: false
        onTriggered: netCheckProc.running = true
    }

    // ─── Volume readout (click opens the volume panel) ────────────────
    Tui.TuiButton {
        text: {
            const pct = Math.round(root.volume * 100) + "%";
            const glyph = root.volumeMuted ? "󰖁"
                : root.volume > 0.66 ? "󰕾"
                : root.volume > 0.33 ? "󰖀" : "󰕿";
            return glyph + " " + pct;
        }
        fontSize: Theme.fontSizeSmall
        active: PanelState.rightPanelContext === "volume"
        activeColor: Theme.utility
        onClicked: PanelState.openRight("volume")

        Layout.alignment: Qt.AlignVCenter
    }

    // ─── Network state (WiFi or Ethernet; click opens network) ────────
    Tui.TuiButton {
        text: root.hasEthernet ? "󰈀" : "󰖩"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "wifi"
        activeColor: Theme.accent
        onClicked: PanelState.openRight("wifi")

        Layout.alignment: Qt.AlignVCenter
    }

    // ─── Notifications ────────────────────────────────────────────────
    Tui.TuiButton {
        text: "󰂚"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "notifications"
        activeColor: Theme.warning
        onClicked: PanelState.openRight("notifications")

        // Dot indicator when notifications are pending
        Text {
            visible: NotificationManager.count > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -2
            anchors.rightMargin: -2
            text: Theme.dotSmall
            color: Theme.warning
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }

        Layout.alignment: Qt.AlignVCenter
    }

    // ─── Context menu (opens the rail menu list) ──────────────────────
    Tui.TuiButton {
        text: "☰"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "menu"
        activeColor: Theme.accentSecondary
        onClicked: PanelState.openRight("menu")

        Layout.alignment: Qt.AlignVCenter
    }
}