import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// Brightness control panel — mirrors VolumeControl pattern.
// Lists backlight devices, shows progress bar, scroll-to-adjust.
// Uses brightnessctl for querying and setting brightness.
Item {
    id: root

    // ─── Data model ──────────────────────────────────────────────────
    property var devices: []
    property real currentBrightness: 0.0  // 0.0 to 1.0
    property int currentPercent: Math.round(currentBrightness * 100)
    property string activeDevice: ""

    // ─── Device enumeration ──────────────────────────────────────────
    // `brightnessctl -m -l` outputs machine-readable lines:
    // device,class,current,percentage,max
    // e.g.: intel_backlight,backlight,600,47%,1267
    Process {
        id: deviceListProc
        command: ["brightnessctl", "-m", "-l"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                deviceListProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                let result = [];
                const lines = deviceListProc.buffer.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line === "") continue;
                    // Format: device,class,current,percentage,max
                    const parts = line.split(",");
                    if (parts.length >= 5) {
                        const name = parts[0];
                        const cls = parts[1];  // "backlight" or "leds"
                        const current = parseInt(parts[2]) || 0;
                        const pctStr = parts[3].replace("%", "");
                        const pct = parseInt(pctStr) || 0;
                        const max = parseInt(parts[4]) || 100;

                        // Only show backlight devices (skip keyboard LEDs etc.)
                        if (cls === "backlight") {
                            result.push({
                                name: name,
                                brightness: pct / 100.0,
                                current: current,
                                max: max
                            });
                        }
                    }
                }

                root.devices = result;

                // Set active device to first if not set
                if (root.activeDevice === "" && result.length > 0) {
                    root.activeDevice = result[0].name;
                }

                // Update current brightness from active device
                for (let i = 0; i < result.length; i++) {
                    if (result[i].name === root.activeDevice) {
                        root.currentBrightness = result[i].brightness;
                        break;
                    }
                }

                deviceListProc.buffer = "";
                refreshTimer.start();
            }
        }
    }

    // ─── Quick brightness poll (active device only) ──────────────────
    Process {
        id: brightProc
        command: ["brightnessctl", "-m", "-d", root.activeDevice]
        running: root.activeDevice !== ""

        stdout: SplitParser {
            onRead: data => {
                // Format: device,class,current,percentage,max
                const parts = data.split(",");
                if (parts.length >= 5) {
                    const pctStr = parts[3].replace("%", "");
                    const pct = parseInt(pctStr) || 0;
                    root.currentBrightness = pct / 100.0;
                }
            }
        }

        onRunningChanged: {
            if (!running) brightPollTimer.start();
        }
    }

    Timer {
        id: brightPollTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (root.activeDevice !== "") brightProc.running = true;
        }
    }

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: false
        onTriggered: deviceListProc.running = true
    }

    Component.onCompleted: {
        deviceListProc.running = true;
    }

    // ─── Brightness adjustment commands ──────────────────────────────
    Process {
        id: cmdProc
        running: false
    }

    function setBrightness(percent) {
        const clamped = Math.max(1, Math.min(100, percent));  // never go to 0 (screen off)
        cmdProc.command = ["brightnessctl", "-d", root.activeDevice, "set", clamped + "%"];
        cmdProc.running = true;
        root.currentBrightness = clamped / 100.0;
    }

    function setDevice(deviceName) {
        root.activeDevice = deviceName;
        // Refresh to get that device's brightness
        brightProc.running = true;
    }

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.itemSpacing

        // ─── Current brightness display ──────────────────────────────
        RowLayout {
            id: brightnessRow
            Layout.fillWidth: true
            spacing: 6

            Tui.TuiText {
                text: root.currentPercent > 66 ? "󰃠" : root.currentPercent > 33 ? "󰃟" : "󰃞"
                textColor: Theme.nord13
                font.pixelSize: Theme.fontSizeLarge
            }

            // Brightness progress bar
            Tui.TuiProgress {
                Layout.fillWidth: true
                value: root.currentBrightness
                filledColor: Theme.nord13
            }

            Tui.TuiText {
                text: root.currentPercent + "%"
                textColor: Theme.textPrimary
            }
        }

        // Scroll wheel overlay for the entire brightness row
        MouseArea {
            Layout.fillWidth: true
            Layout.preferredHeight: brightnessRow.implicitHeight
            Layout.topMargin: -brightnessRow.implicitHeight - Theme.itemSpacing
            z: 10
            propagateComposedEvents: true
            acceptedButtons: Qt.NoButton  // don't eat clicks
            onWheel: wheel => {
                const delta = wheel.angleDelta.y > 0 ? 5 : -5;
                const newBright = Math.max(1, Math.min(100, root.currentPercent + delta));
                root.setBrightness(newBright);
            }
        }

        // ─── Controls row ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.itemSpacing

            Tui.TuiButton {
                text: "[-]"
                onClicked: {
                    const newBright = Math.max(1, root.currentPercent - 5);
                    root.setBrightness(newBright);
                }
            }

            Tui.TuiButton {
                text: "[min]"
                onClicked: root.setBrightness(1)
            }

            Tui.TuiButton {
                text: "[max]"
                onClicked: root.setBrightness(100)
            }

            Tui.TuiButton {
                text: "[+]"
                onClicked: {
                    const newBright = Math.min(100, root.currentPercent + 5);
                    root.setBrightness(newBright);
                }
            }
        }

        // ─── Separator ───────────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: Theme.boxHorizontal.repeat(40)
            textColor: Theme.border
        }

        // ─── Device list ─────────────────────────────────────────────
        Tui.TuiText {
            text: "devices"
            textColor: Theme.textMuted
            font.bold: true
        }

        Repeater {
            model: root.devices

            RowLayout {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: 6

                // Tree glyph
                Tui.TuiText {
                    text: index === root.devices.length - 1 ? Theme.treeEnd : Theme.treeBranch
                    textColor: Theme.border
                }

                // Device name (clickable to switch)
                Tui.TuiButton {
                    text: modelData.name
                    active: modelData.name === root.activeDevice
                    activeColor: Theme.nord13
                    onClicked: root.setDevice(modelData.name)
                    Layout.fillWidth: true
                }

                // Device brightness
                Tui.TuiText {
                    text: Math.round(modelData.brightness * 100) + "%"
                    textColor: Theme.textMuted
                }
            }
        }

        // ─── Spacer ─────────────────────────────────────────────────
        Item { Layout.fillHeight: true }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: "scroll:adjust  click:switch device"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
