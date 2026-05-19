import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.theme

RowLayout {
    spacing: 10

    // --- Network ---
    Text {
        id: netIcon
        property string state: "unknown"
        text: state === "enabled" ? "󰖩" : state === "disabled" ? "󰖪" : "󰖩"
        color: state === "enabled" ? Theme.fg : Theme.fgDim
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamily
    }

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "WIFI", "g"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim().toLowerCase();
                if (line === "enabled" || line === "disabled") {
                    netIcon.state = line;
                }
            }
        }

        onRunningChanged: {
            if (!running) pollNet.start();
        }
    }

    Timer {
        id: pollNet
        interval: 5000
        repeat: false
        onTriggered: netProc.running = true
    }

    // --- Bluetooth ---
    Text {
        id: btIcon
        property bool powered: false
        text: powered ? "󰂯" : "󰂲"
        color: powered ? Theme.fg : Theme.fgDim
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamily
    }

    Process {
        id: btProc
        command: ["bluetoothctl", "show"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("Powered: yes") !== -1) {
                    btIcon.powered = true;
                } else if (data.indexOf("Powered: no") !== -1) {
                    btIcon.powered = false;
                }
            }
        }

        onRunningChanged: {
            if (!running) pollBt.start();
        }
    }

    Timer {
        id: pollBt
        interval: 5000
        repeat: false
        onTriggered: btProc.running = true
    }

    // --- Volume ---
    Text {
        id: volIcon
        property real volume: 0.0
        property bool muted: false
        text: muted ? "󰖁" : volume > 0.66 ? "󰕾" : volume > 0.33 ? "󰖀" : volume > 0 ? "󰕿" : "󰖁"
        color: muted ? Theme.fgDim : Theme.fg
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamily
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                // Output: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
                volIcon.muted = data.indexOf("[MUTED]") !== -1;
                const match = data.match(/Volume:\s+([\d.]+)/);
                if (match) volIcon.volume = parseFloat(match[1]);
            }
        }

        onRunningChanged: {
            if (!running) pollVol.start();
        }
    }

    Timer {
        id: pollVol
        interval: 2000
        repeat: false
        onTriggered: volProc.running = true
    }
}
