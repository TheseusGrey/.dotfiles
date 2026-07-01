import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// Bluetooth panel — lists paired/available devices.
// Shows connection status, device type icons. Click to connect/disconnect.
// Uses bluetoothctl for all operations.
//
// bluetoothctl commands used:
//   bluetoothctl devices Paired
//   bluetoothctl devices Connected
//   bluetoothctl info <MAC>        → get device type/icon
//   bluetoothctl connect <MAC>
//   bluetoothctl disconnect <MAC>
//   bluetoothctl scan on/off
//   bluetoothctl show              → adapter powered state
Item {
    id: root

    // ─── Data model ──────────────────────────────────────────────────
    property var devices: []
    property var connectedMacs: ({})
    property bool powered: false
    property bool scanning: false

    // ─── Adapter state check ─────────────────────────────────────────
    Process {
        id: adapterProc
        command: ["bluetoothctl", "show"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                adapterProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                root.powered = adapterProc.buffer.indexOf("Powered: yes") !== -1;
                adapterProc.buffer = "";
                adapterPollTimer.start();
            }
        }
    }

    Timer {
        id: adapterPollTimer
        interval: 5000
        repeat: false
        onTriggered: adapterProc.running = true
    }

    // ─── Connected devices check ─────────────────────────────────────
    Process {
        id: connectedProc
        command: ["bluetoothctl", "devices", "Connected"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                connectedProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                let macs = {};
                const lines = connectedProc.buffer.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    // Format: "Device XX:XX:XX:XX:XX:XX Name"
                    const match = lines[i].match(/Device\s+([0-9A-Fa-f:]{17})/);
                    if (match) macs[match[1]] = true;
                }
                root.connectedMacs = macs;
                connectedProc.buffer = "";
            }
        }
    }

    // ─── Paired device enumeration ───────────────────────────────────
    Process {
        id: pairedProc
        command: ["bluetoothctl", "devices", "Paired"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                pairedProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                let result = [];
                const lines = pairedProc.buffer.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line === "") continue;
                    // Format: "Device XX:XX:XX:XX:XX:XX Device Name"
                    const match = line.match(/Device\s+([0-9A-Fa-f:]{17})\s+(.+)/);
                    if (match) {
                        const mac = match[1];
                        const name = match[2];
                        result.push({
                            mac: mac,
                            name: name,
                            connected: root.connectedMacs[mac] === true
                        });
                    }
                }

                // Sort: connected first, then alphabetical
                result.sort((a, b) => {
                    if (a.connected && !b.connected) return -1;
                    if (!a.connected && b.connected) return 1;
                    return a.name.localeCompare(b.name);
                });

                root.devices = result;
                pairedProc.buffer = "";
                refreshTimer.start();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: false
        onTriggered: {
            connectedProc.running = true;
            // Chain: after connected check completes, refresh paired list
            pairedRefreshTimer.start();
        }
    }

    Timer {
        id: pairedRefreshTimer
        interval: 500
        repeat: false
        onTriggered: pairedProc.running = true
    }

    Component.onCompleted: {
        adapterProc.running = true;
        connectedProc.running = true;
        // Small delay so connectedMacs is populated before pairedProc uses it
        Qt.callLater(() => { pairedProc.running = true; });
    }

    // ─── Commands ────────────────────────────────────────────────────
    Process {
        id: cmdProc
        running: false
    }

    function connectDevice(mac) {
        cmdProc.command = ["bluetoothctl", "connect", mac];
        cmdProc.running = true;
        refreshAfterCmd.start();
    }

    function disconnectDevice(mac) {
        cmdProc.command = ["bluetoothctl", "disconnect", mac];
        cmdProc.running = true;
        refreshAfterCmd.start();
    }

    function togglePower() {
        cmdProc.command = ["bluetoothctl", "power", root.powered ? "off" : "on"];
        cmdProc.running = true;
        root.powered = !root.powered;
    }

    function toggleScan() {
        root.scanning = !root.scanning;
        cmdProc.command = ["bluetoothctl", "scan", root.scanning ? "on" : "off"];
        cmdProc.running = true;
    }

    Timer {
        id: refreshAfterCmd
        interval: 2000
        repeat: false
        onTriggered: {
            connectedProc.running = true;
            pairedRefreshTimer.start();
        }
    }

    // ─── Device type icon mapping ────────────────────────────────────
    function deviceIcon(name) {
        const lower = name.toLowerCase();
        if (lower.indexOf("airpods") !== -1 || lower.indexOf("headphone") !== -1 ||
            lower.indexOf("buds") !== -1 || lower.indexOf("earphone") !== -1)
            return "󰋋";
        if (lower.indexOf("speaker") !== -1 || lower.indexOf("soundbar") !== -1)
            return "󰓃";
        if (lower.indexOf("keyboard") !== -1 || lower.indexOf("keychron") !== -1)
            return "󰌌";
        if (lower.indexOf("mouse") !== -1 || lower.indexOf("trackpad") !== -1)
            return "󰍽";
        if (lower.indexOf("controller") !== -1 || lower.indexOf("gamepad") !== -1 ||
            lower.indexOf("xbox") !== -1 || lower.indexOf("dualsense") !== -1)
            return "󰊗";
        if (lower.indexOf("phone") !== -1 || lower.indexOf("iphone") !== -1)
            return "󰏲";
        if (lower.indexOf("watch") !== -1)
            return "󰖉";
        return "󰂯";  // generic bluetooth
    }

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.itemSpacing

        // ─── Status row ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tui.TuiText {
                text: root.powered ? "󰂯" : "󰂲"
                textColor: root.powered ? Theme.nord9 : Theme.textMuted
                font.pixelSize: Theme.fontSizeLarge
            }

            Tui.TuiText {
                text: {
                    if (!root.powered) return "bluetooth off";
                    const connCount = Object.keys(root.connectedMacs).length;
                    if (connCount > 0) return connCount + " connected";
                    return "no connections";
                }
                textColor: root.powered ? Theme.textBright : Theme.textMuted
                font.bold: root.powered
                font.italic: !root.powered  // italic for off/disconnected state
                Layout.fillWidth: true
            }

            Tui.TuiSpinner {
                running: root.scanning
                spinnerColor: Theme.nord9
            }
        }

        // ─── Controls row ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.itemSpacing

            Tui.TuiButton {
                text: root.powered ? "[off]" : "[on]"
                activeColor: Theme.nord9
                active: !root.powered
                onClicked: root.togglePower()
            }

            Tui.TuiButton {
                visible: root.powered
                text: root.scanning ? "[stop scan]" : "[scan]"
                active: root.scanning
                activeColor: Theme.nord9
                onClicked: root.toggleScan()
            }
        }

        // ─── Separator ───────────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: Theme.boxHorizontal.repeat(40)
            textColor: Theme.border
        }

        // ─── Device header ───────────────────────────────────────────
        Tui.TuiText {
            text: "paired devices"
            textColor: Theme.textMuted
            font.bold: true
        }

        // ─── Device list ─────────────────────────────────────────────
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: deviceList.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: deviceList
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.devices

                    Item {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: deviceRow.implicitHeight

                        RowLayout {
                            id: deviceRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 6

                            // Tree glyph
                            Tui.TuiText {
                                text: index === root.devices.length - 1 ? Theme.treeEnd : Theme.treeBranch
                                textColor: Theme.border
                            }

                            // Connection status dot
                            Tui.TuiText {
                                text: modelData.connected ? Theme.dotFilled : Theme.dotEmpty
                                textColor: modelData.connected ? Theme.nord9 : Theme.textMuted
                            }

                            // Device type icon
                            Tui.TuiText {
                                text: root.deviceIcon(modelData.name)
                                textColor: modelData.connected ? Theme.nord9 : Theme.textMuted
                            }

                            // Device name (clickable to connect/disconnect)
                            Tui.TuiButton {
                                text: {
                                    const name = modelData.name;
                                    return name.length > 18 ? name.substring(0, 17) + "…" : name;
                                }
                                active: modelData.connected
                                activeColor: Theme.nord9
                                onClicked: {
                                    if (modelData.connected) {
                                        root.disconnectDevice(modelData.mac);
                                    } else {
                                        root.connectDevice(modelData.mac);
                                    }
                                }
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Empty state
                Tui.TuiText {
                    visible: root.devices.length === 0
                    text: root.powered ? "no paired devices" : "bluetooth is off"
                    textColor: Theme.textMuted
                }
            }
        }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: "click:connect/disconnect  ●:connected"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
