import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// WiFi panel — lists visible networks, shows signal strength,
// allows connect/disconnect. Uses nmcli for all operations.
//
// nmcli commands used:
//   nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE device wifi list
//   nmcli device wifi connect <SSID>
//   nmcli device disconnect <iface>
//   nmcli -t -f NAME,TYPE connection show --active
Item {
    id: root

    // ─── Data model ──────────────────────────────────────────────────
    property var networks: []
    property var activeConnections: []  // [{name, type, device}]
    property string connectedSsid: ""
    property string wifiInterface: "wlan0"
    property bool wifiEnabled: true
    property bool scanning: false

    // ─── Network list scan ───────────────────────────────────────────
    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                scanProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                let result = [];
                let seen = {};
                const lines = scanProc.buffer.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line === "") continue;
                    // Format: SSID:SIGNAL:SECURITY:IN-USE
                    // Note: SSID can contain colons, so we parse from the right
                    const parts = line.split(":");
                    if (parts.length < 4) continue;

                    const inUse = parts[parts.length - 1] === "*";
                    const security = parts[parts.length - 2];
                    const signal = parseInt(parts[parts.length - 3]) || 0;
                    // SSID is everything before the last 3 fields
                    const ssid = parts.slice(0, parts.length - 3).join(":");

                    if (ssid === "" || ssid === "--") continue;
                    if (seen[ssid]) continue;  // deduplicate
                    seen[ssid] = true;

                    if (inUse) root.connectedSsid = ssid;

                    result.push({
                        ssid: ssid,
                        signal: signal,
                        security: security,
                        connected: inUse
                    });
                }

                // Sort: connected first, then by signal strength descending
                result.sort((a, b) => {
                    if (a.connected && !b.connected) return -1;
                    if (!a.connected && b.connected) return 1;
                    return b.signal - a.signal;
                });

                root.networks = result;
                root.scanning = false;
                scanProc.buffer = "";
                refreshTimer.start();
            }
        }
    }

    // ─── WiFi state check ────────────────────────────────────────────
    Process {
        id: wifiStateProc
        command: ["nmcli", "-t", "-f", "WIFI", "g"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim().toLowerCase();
                root.wifiEnabled = (line === "enabled");
            }
        }

        onRunningChanged: {
            if (!running) wifiStatePollTimer.start();
        }
    }

    Timer {
        id: wifiStatePollTimer
        interval: 5000
        repeat: false
        onTriggered: wifiStateProc.running = true
    }

    // ─── Active connections polling ──────────────────────────────────
    Process {
        id: activeConnProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                activeConnProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                let result = [];
                const lines = activeConnProc.buffer.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line === "") continue;
                    const parts = line.split(":");
                    if (parts.length < 3) continue;
                    // NAME:TYPE:DEVICE — name can contain colons, parse from right
                    const device = parts[parts.length - 1];
                    const type = parts[parts.length - 2];
                    const name = parts.slice(0, parts.length - 2).join(":");
                    // Skip loopback and bridge connections
                    if (device === "lo" || type === "loopback" || type === "bridge") continue;
                    result.push({
                        name: name,
                        type: type,
                        device: device,
                        isWired: type === "802-3-ethernet",
                        isWifi: type === "802-11-wireless"
                    });
                }
                root.activeConnections = result;
                activeConnProc.buffer = "";
                activeConnPollTimer.start();
            }
        }
    }

    Timer {
        id: activeConnPollTimer
        interval: 5000
        repeat: false
        onTriggered: activeConnProc.running = true
    }

    Timer {
        id: refreshTimer
        interval: 10000  // WiFi scan every 10s (not too aggressive)
        repeat: false
        onTriggered: {
            root.scanning = true;
            scanProc.running = true;
        }
    }

    Component.onCompleted: {
        scanProc.running = true;
    }

    // ─── Commands ────────────────────────────────────────────────────
    Process {
        id: cmdProc
        running: false
    }

    function connectTo(ssid) {
        cmdProc.command = ["nmcli", "device", "wifi", "connect", ssid];
        cmdProc.running = true;
        // Refresh after a brief delay to get new state
        refreshAfterCmd.start();
    }

    function disconnect() {
        cmdProc.command = ["nmcli", "device", "disconnect", root.wifiInterface];
        cmdProc.running = true;
        root.connectedSsid = "";
        refreshAfterCmd.start();
    }

    function toggleWifi() {
        const action = root.wifiEnabled ? "off" : "on";
        cmdProc.command = ["nmcli", "radio", "wifi", action];
        cmdProc.running = true;
        root.wifiEnabled = !root.wifiEnabled;
        refreshAfterCmd.start();
    }

    function rescan() {
        root.scanning = true;
        scanProc.running = true;
    }

    Timer {
        id: refreshAfterCmd
        interval: 2000
        repeat: false
        onTriggered: {
            root.scanning = true;
            scanProc.running = true;
        }
    }

    // ─── Signal strength to bar characters ───────────────────────────
    function signalBars(strength) {
        // 0-100 → 0-4 bars using block chars
        if (strength >= 80) return "▂▄▆█";
        if (strength >= 60) return "▂▄▆░";
        if (strength >= 40) return "▂▄░░";
        if (strength >= 20) return "▂░░░";
        return "░░░░";
    }

    function signalColor(strength) {
        if (strength >= 60) return Theme.success;
        if (strength >= 40) return Theme.nord13;
        return Theme.error;
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
                text: root.wifiEnabled ? "󰖩" : "󰖪"
                textColor: root.wifiEnabled ? Theme.nord8 : Theme.textMuted
                font.pixelSize: Theme.fontSizeLarge
            }

            Tui.TuiText {
                text: root.connectedSsid !== "" ? root.connectedSsid : root.wifiEnabled ? "not connected" : "wifi off"
                textColor: root.connectedSsid !== "" ? Theme.textBright : Theme.textMuted
                font.bold: root.connectedSsid !== ""
                font.italic: root.connectedSsid === ""  // italic for disconnected status
                Layout.fillWidth: true
            }

            Tui.TuiSpinner {
                running: root.scanning
                spinnerColor: Theme.nord8
            }
        }

        // ─── Controls row ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.itemSpacing

            Tui.TuiButton {
                text: root.wifiEnabled ? "[disable]" : "[enable]"
                activeColor: Theme.nord8
                active: !root.wifiEnabled
                onClicked: root.toggleWifi()
            }

            Tui.TuiButton {
                text: "[scan]"
                onClicked: root.rescan()
            }

            Tui.TuiButton {
                visible: root.connectedSsid !== ""
                text: "[disconnect]"
                activeColor: Theme.error
                onClicked: root.disconnect()
            }
        }

        // ─── Separator ───────────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: Theme.boxHorizontal.repeat(40)
            textColor: Theme.border
        }

        // ─── Active connections ──────────────────────────────────────
        Tui.TuiText {
            text: "connections"
            textColor: Theme.textPrimary
            font.bold: true
        }

        Repeater {
            model: root.activeConnections

            RowLayout {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: 6

                // Tree glyph
                Tui.TuiText {
                    text: index === root.activeConnections.length - 1 ? Theme.treeEnd : Theme.treeBranch
                    textColor: Theme.accentSecondary
                }

                // Connection type icon
                Tui.TuiText {
                    text: modelData.isWired ? "󰈀" : modelData.isWifi ? "󰖩" : "󰛳"
                    textColor: modelData.isWired ? Theme.success : Theme.nord8
                    font.pixelSize: Theme.fontSizeIcon
                }

                // Connection name + device
                Tui.TuiText {
                    text: {
                        const name = modelData.name;
                        const truncated = name.length > 18 ? name.substring(0, 17) + "…" : name;
                        return truncated + " — " + modelData.device;
                    }
                    textColor: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                    Layout.fillWidth: true
                }

                // Connected indicator
                Tui.TuiText {
                    text: Theme.dotFilled
                    textColor: Theme.success
                }
            }
        }

        // Empty state for connections
        Tui.TuiText {
            visible: root.activeConnections.length === 0
            text: "  no active connections"
            textColor: Theme.textMuted
            font.italic: true
            font.pixelSize: Theme.fontSizeSmall
        }

        // ─── Separator ───────────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: Theme.boxHorizontal.repeat(40)
            textColor: Theme.border
        }

        // ─── Network header ──────────────────────────────────────────
        Tui.TuiText {
            text: "wifi networks"
            textColor: Theme.textPrimary
            font.bold: true
        }

        // ─── Network list ────────────────────────────────────────────
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: networkList.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: networkList
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.networks

                    Item {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: networkRow.implicitHeight

                        RowLayout {
                            id: networkRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 6

                            // Tree glyph
                            Tui.TuiText {
                                text: index === root.networks.length - 1 ? Theme.treeEnd : Theme.treeBranch
                                textColor: Theme.accentSecondary
                            }

                            // Connected indicator
                            Tui.TuiText {
                                text: modelData.connected ? Theme.dotFilled : " "
                                textColor: Theme.nord8
                            }

                            // SSID (clickable to connect)
                            Tui.TuiButton {
                                text: {
                                    const name = modelData.ssid;
                                    return name.length > 20 ? name.substring(0, 19) + "…" : name;
                                }
                                active: modelData.connected
                                activeColor: Theme.nord8
                                onClicked: {
                                    if (modelData.connected) {
                                        root.disconnect();
                                    } else {
                                        root.connectTo(modelData.ssid);
                                    }
                                }
                                Layout.fillWidth: true
                            }

                            // Security icon
                            Tui.TuiText {
                                visible: modelData.security !== "" && modelData.security !== "--"
                                text: "󰒃"
                                textColor: Theme.textMuted
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            // Signal strength bars
                            Text {
                                text: root.signalBars(modelData.signal)
                                color: root.signalColor(modelData.signal)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }
                    }
                }
            }
        }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: "click:connect/disconnect  ●:active"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
