import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components as Tui

// System stats — CPU and Memory usage as TUI progress bars.
//
// Visual:
//   cpu ▌▌▌▌░░░░░░  42%
//   mem ▌▌▌▌▌▌░░░░  63%
//
ColumnLayout {
    id: root
    spacing: 4

    property real cpuUsage: 0.0  // 0.0 - 1.0
    property real memUsage: 0.0  // 0.0 - 1.0
    property string memText: ""  // e.g. "4.2G/16G"

    // Previous CPU values for delta calculation
    property real prevIdle: 0
    property real prevTotal: 0

    // ─── CPU Row ───
    RowLayout {
        spacing: 6
        Layout.fillWidth: true

        Tui.TuiText {
            text: "cpu"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
            Layout.preferredWidth: 24
        }

        Tui.TuiProgress {
            value: root.cpuUsage
            barLength: 10
            filledColor: root.cpuUsage > 0.8 ? Theme.error
                       : root.cpuUsage > 0.6 ? Theme.warning
                       : Theme.nord7
        }

        Tui.TuiText {
            text: `${Math.round(root.cpuUsage * 100)}%`
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
            Layout.preferredWidth: 28
            horizontalAlignment: Text.AlignRight
        }
    }

    // ─── Memory Row ───
    RowLayout {
        spacing: 6
        Layout.fillWidth: true

        Tui.TuiText {
            text: "mem"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
            Layout.preferredWidth: 24
        }

        Tui.TuiProgress {
            value: root.memUsage
            barLength: 10
            filledColor: root.memUsage > 0.8 ? Theme.error
                       : root.memUsage > 0.6 ? Theme.warning
                       : Theme.nord9
        }

        Tui.TuiText {
            text: root.memText !== "" ? root.memText : `${Math.round(root.memUsage * 100)}%`
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignRight
        }
    }

    // ─── CPU Polling ───
    // Reads /proc/stat: "cpu  user nice system idle iowait irq softirq"
    // CPU% = 1 - (delta_idle / delta_total)
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts[0] !== "cpu") return;

                // Sum all fields (user, nice, system, idle, iowait, irq, softirq, steal)
                let total = 0;
                for (let i = 1; i < parts.length; i++) {
                    total += parseInt(parts[i]) || 0;
                }
                const idle = (parseInt(parts[4]) || 0) + (parseInt(parts[5]) || 0); // idle + iowait

                if (root.prevTotal > 0) {
                    const deltaTotal = total - root.prevTotal;
                    const deltaIdle = idle - root.prevIdle;
                    if (deltaTotal > 0) {
                        root.cpuUsage = 1.0 - (deltaIdle / deltaTotal);
                    }
                }

                root.prevIdle = idle;
                root.prevTotal = total;
            }
        }

        onRunningChanged: {
            if (!running) cpuTimer.start();
        }
    }

    Timer {
        id: cpuTimer
        interval: 2000
        onTriggered: cpuProc.running = true
    }

    // ─── Memory Polling ───
    // Reads /proc/meminfo for MemTotal, MemAvailable
    Process {
        id: memProc
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                memProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                // Parse buffer
                const lines = memProc.buffer.trim().split("\n");
                let memTotal = 0;
                let memAvail = 0;

                for (const line of lines) {
                    const match = line.match(/^(\w+):\s+(\d+)/);
                    if (match) {
                        const val = parseInt(match[2]); // in kB
                        if (match[1] === "MemTotal") memTotal = val;
                        else if (match[1] === "MemAvailable") memAvail = val;
                    }
                }

                if (memTotal > 0) {
                    const used = memTotal - memAvail;
                    root.memUsage = used / memTotal;

                    // Format as "X.XG/Y.YG"
                    const usedG = (used / 1048576).toFixed(1);
                    const totalG = (memTotal / 1048576).toFixed(1);
                    root.memText = `${usedG}/${totalG}G`;
                }

                memProc.buffer = "";
                memTimer.start();
            }
        }
    }

    Timer {
        id: memTimer
        interval: 5000
        onTriggered: memProc.running = true
    }
}
