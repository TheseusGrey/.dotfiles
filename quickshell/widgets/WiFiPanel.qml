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

    // ─── Network speed tracking ──────────────────────────────────────
    property real rxBytesPerSec: 0
    property real txBytesPerSec: 0
    property real lastRxBytes: -1
    property real lastTxBytes: -1
    property string speedInterface: ""  // auto-detected from active connections

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1048576) return (bytesPerSec / 1048576).toFixed(1) + " MB/s";
        if (bytesPerSec >= 1024) return (bytesPerSec / 1024).toFixed(0) + " KB/s";
        return bytesPerSec.toFixed(0) + " B/s";
    }

    // Auto-detect which interface to monitor (prefer wifi, fall back to wired)
    onActiveConnectionsChanged: {
        let iface = "";
        for (let i = 0; i < activeConnections.length; i++) {
            const conn = activeConnections[i];
            if (conn.isWifi) { iface = conn.device; break; }
            if (conn.isWired && iface === "") iface = conn.device;
        }
        if (iface !== "" && iface !== speedInterface) {
            speedInterface = iface;
            lastRxBytes = -1;
            lastTxBytes = -1;
        }
    }

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

    // ─── Network speed polling ───────────────────────────────────────
    // Reads /sys/class/net/<iface>/statistics/{rx,tx}_bytes every 2s
    Process {
        id: rxProc
        command: ["cat", "/sys/class/net/" + root.speedInterface + "/statistics/rx_bytes"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const bytes = parseFloat(data.trim());
                if (isNaN(bytes)) return;
                if (root.lastRxBytes >= 0) {
                    root.rxBytesPerSec = Math.max(0, (bytes - root.lastRxBytes) / 2);
                }
                root.lastRxBytes = bytes;
            }
        }
    }

    Process {
        id: txProc
        command: ["cat", "/sys/class/net/" + root.speedInterface + "/statistics/tx_bytes"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const bytes = parseFloat(data.trim());
                if (isNaN(bytes)) return;
                if (root.lastTxBytes >= 0) {
                    root.txBytesPerSec = Math.max(0, (bytes - root.lastTxBytes) / 2);
                }
                root.lastTxBytes = bytes;
            }
        }
    }

    Timer {
        id: speedTimer
        interval: 2000
        repeat: true
        running: root.speedInterface !== "" && root.visible
        onTriggered: {
            rxProc.command = ["cat", "/sys/class/net/" + root.speedInterface + "/statistics/rx_bytes"];
            txProc.command = ["cat", "/sys/class/net/" + root.speedInterface + "/statistics/tx_bytes"];
            rxProc.running = true;
            txProc.running = true;
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

    // ─── UFW firewall status ─────────────────────────────────────────
    property var ufwBlocked: []      // [{src, dst, port, proto, time}]
    property int ufwBlockCount: 0
    property string ufwStatus: ""    // "active", "inactive", or ""

    Process {
        id: ufwStatusProc
        command: ["systemctl", "is-active", "ufw"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim().toLowerCase();
                if (line === "active") root.ufwStatus = "active";
                else root.ufwStatus = "inactive";
            }
        }

        onRunningChanged: {
            if (!running) ufwPollTimer.start();
        }
    }

    Process {
        id: ufwLogProc
        command: ["dmesg", "--time-format", "reltime", "-l", "warn", "--facility", "kern"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                ufwLogProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                let blocked = [];
                const lines = ufwLogProc.buffer.trim().split("\n");
                for (let i = lines.length - 1; i >= 0 && blocked.length < 5; i--) {
                    const line = lines[i];
                    if (line.indexOf("[UFW BLOCK]") < 0) continue;

                    // Extract fields from UFW log
                    const srcMatch = line.match(/SRC=([^\s]+)/);
                    const dptMatch = line.match(/DPT=([^\s]+)/);
                    const protoMatch = line.match(/PROTO=([^\s]+)/);
                    const dstMatch = line.match(/DST=([^\s]+)/);

                    blocked.push({
                        src: srcMatch ? srcMatch[1] : "?",
                        dst: dstMatch ? dstMatch[1] : "?",
                        port: dptMatch ? dptMatch[1] : "?",
                        proto: protoMatch ? protoMatch[1].toLowerCase() : "?"
                    });
                }

                root.ufwBlocked = blocked;
                // Count total blocks in buffer
                let count = 0;
                for (let j = 0; j < lines.length; j++) {
                    if (lines[j].indexOf("[UFW BLOCK]") >= 0) count++;
                }
                root.ufwBlockCount = count;
                ufwLogProc.buffer = "";
                ufwPollTimer.start();
            }
        }
    }

    Timer {
        id: ufwPollTimer
        interval: 15000  // Check UFW every 15s
        repeat: false
        onTriggered: {
            ufwStatusProc.running = true;
            ufwLogProc.running = true;
        }
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

        // ─── Network speed ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.speedInterface !== "" && (root.rxBytesPerSec > 0 || root.txBytesPerSec > 0 || root.lastRxBytes >= 0)

            Tui.TuiText {
                text: "↓ " + root.formatSpeed(root.rxBytesPerSec)
                textColor: Theme.success
                font.pixelSize: Theme.fontSizeSmall
            }

            Tui.TuiText {
                text: "↑ " + root.formatSpeed(root.txBytesPerSec)
                textColor: Theme.nord13
                font.pixelSize: Theme.fontSizeSmall
            }

            Tui.TuiText {
                text: "(" + root.speedInterface + ")"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeSmall
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

        // ─── UFW Firewall ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.ufwStatus !== ""

            Tui.TuiText {
                text: "firewall"
                textColor: Theme.textPrimary
                font.bold: true
            }

            Tui.TuiText {
                text: root.ufwStatus === "active" ? "●" : "○"
                textColor: root.ufwStatus === "active" ? Theme.success : Theme.error
            }

            Tui.TuiText {
                text: root.ufwStatus
                textColor: root.ufwStatus === "active" ? Theme.success : Theme.error
                font.pixelSize: Theme.fontSizeSmall
            }

            Item { Layout.fillWidth: true }

            Tui.TuiText {
                visible: root.ufwBlockCount > 0
                text: root.ufwBlockCount + " blocked"
                textColor: Theme.nord13
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        // Recent blocks list
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            visible: root.ufwBlocked.length > 0 && root.ufwStatus === "active"

            Repeater {
                model: root.ufwBlocked

                RowLayout {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: 4

                    Tui.TuiText {
                        text: index === root.ufwBlocked.length - 1 ? Theme.treeEnd : Theme.treeBranch
                        textColor: Theme.accentSecondary
                    }

                    Tui.TuiText {
                        text: "✗"
                        textColor: Theme.error
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Tui.TuiText {
                        text: {
                            const src = modelData.src.length > 15
                                ? modelData.src.substring(0, 14) + "…"
                                : modelData.src;
                            return src + ":" + modelData.port + "/" + modelData.proto;
                        }
                        textColor: Theme.textMuted
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.fillWidth: true
                    }
                }
            }
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
