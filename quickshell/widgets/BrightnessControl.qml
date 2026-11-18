import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// Brightness control panel — mirrors VolumeControl pattern.
// Uses a hardware backlight when one exists. On desktops (no backlight device)
// it falls back to hyprsunset gamma dimming, and the same panel carries the
// eye-protection (blue-light) controls.
Item {
    id: root

    // ─── Data model ──────────────────────────────────────────────────
    property var devices: []
    property real currentBrightness: 0.0  // 0.0 to 1.0
    property int currentPercent: Math.round(currentBrightness * 100)
    property string activeDevice: ""
    property bool devicesLoaded: false

    // No backlight device means software dimming through hyprsunset.
    readonly property bool useGamma: root.devicesLoaded && root.devices.length === 0

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
                root.devicesLoaded = true;

                if (result.length === 0) {
                    // Software mode: hyprsunset owns the level.
                    root.activeDevice = "";
                    root.currentBrightness = Hyprsunset.brightness / 100.0;
                } else {
                    // Keep the current device if it still exists, otherwise
                    // fall back to the first one.
                    let known = false;
                    for (let i = 0; i < result.length; i++) {
                        if (result[i].name === root.activeDevice) {
                            known = true;
                            root.currentBrightness = result[i].brightness;
                            break;
                        }
                    }
                    if (!known) {
                        root.activeDevice = result[0].name;
                        root.currentBrightness = result[0].brightness;
                    }
                }

                deviceListProc.buffer = "";
                refreshTimer.start();
            }
        }
    }

    // ─── Quick brightness poll (hardware backlight only) ─────────────
    Process {
        id: brightProc
        command: ["brightnessctl", "-m", "-d", root.activeDevice]
        running: false

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
            if (!running && root.activeDevice !== "") brightPollTimer.start();
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

    // Start the hardware poll once the active device is known
    onActiveDeviceChanged: {
        if (activeDevice !== "") {
            brightPollTimer.stop();
            brightProc.running = true;
        }
    }

    Component.onCompleted: {
        Hyprsunset.reload();
        deviceListProc.running = true;
    }

    // The keybind script can change gamma while the panel is open; keep the
    // slider in step with the service.
    Connections {
        target: Hyprsunset

        function onBrightnessChanged() {
            if (root.useGamma)
                root.currentBrightness = Hyprsunset.brightness / 100.0;
        }
    }

    // ─── Brightness adjustment commands ──────────────────────────────
    Process {
        id: cmdProc
        running: false
    }

    function setBrightness(percent) {
        const clamped = Math.max(1, Math.min(100, Math.round(percent)));  // never go to 0 (screen off)
        if (root.devices.length > 0) {
            cmdProc.command = ["brightnessctl", "-d", root.activeDevice, "set", clamped + "%"];
            cmdProc.running = true;
        } else {
            Hyprsunset.setBrightness(clamped);
        }
        root.currentBrightness = clamped / 100.0;
    }

    function setDevice(deviceName) {
        root.activeDevice = deviceName;
        // Refresh to get that device's brightness
        brightProc.running = true;
    }

    // ─── Keyboard actions ────────────────────────────────────────────
    function adjust(delta) {
        root.setBrightness(Math.max(1, Math.min(100, root.currentPercent + delta)));
    }

    function handlePanelAction(action, arg) {
        switch (action) {
            case "brightnessDown": root.adjust(-5); return true;
            case "brightnessUp":   root.adjust(5); return true;
            case "brightnessMin":  root.setBrightness(1); return true;
            case "brightnessMax":  root.setBrightness(100); return true;
            case "eyeToggle":      Hyprsunset.toggleEye(); return true;
            case "eyeCooler":      Hyprsunset.nudgeTemperature(250); return true;
            case "eyeWarmer":      Hyprsunset.nudgeTemperature(-250); return true;
        }
        return false;
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

            Tui.TuiSlider {
                Layout.fillWidth: true
                value: root.currentBrightness
                filledColor: Theme.nord13
                onValueCommitted: v => root.setBrightness(Math.round(v * 100))
            }

            Tui.TuiText {
                text: root.currentPercent + "%"
                textColor: Theme.textPrimary
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

        // ─── Device list / fallback note ─────────────────────────────
        Tui.TuiText {
            text: "devices"
            textColor: Theme.textPrimary
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
                    textColor: Theme.accentSecondary
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.useGamma

            Tui.TuiText {
                text: Theme.treeEnd
                textColor: Theme.accentSecondary
            }

            Tui.TuiText {
                text: "hyprsunset gamma"
                textColor: Theme.textMuted
                Layout.fillWidth: true
            }

            Tui.TuiText {
                text: "software"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        // ─── Eye protection ──────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: Theme.boxHorizontal.repeat(40)
            textColor: Theme.border
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tui.TuiText {
                text: "󰈈"
                textColor: Hyprsunset.eyeEnabled ? Theme.nord13 : Theme.textMuted
                font.pixelSize: Theme.fontSizeLarge
            }

            Tui.TuiButton {
                text: Hyprsunset.eyeEnabled ? "[x]" : "[ ]"
                variant: "body"
                active: Hyprsunset.eyeEnabled
                activeColor: Theme.nord13
                onClicked: Hyprsunset.toggleEye()
            }

            Tui.TuiText {
                text: "eye protection"
                textColor: Theme.textPrimary
                font.bold: Hyprsunset.eyeEnabled
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
            }

            Tui.TuiText {
                text: Hyprsunset.eyeEnabled ? Hyprsunset.temperature + "K" : "off"
                textColor: Hyprsunset.eyeEnabled ? Theme.nord13 : Theme.textMuted
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            opacity: Hyprsunset.eyeEnabled ? 1.0 : 0.55

            Tui.TuiText {
                text: "cool"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeSmall
            }

            Tui.TuiSlider {
                Layout.fillWidth: true
                value: (6500 - Hyprsunset.temperature) / 4500.0
                filledColor: Theme.nord13
                onValueCommitted: v => Hyprsunset.setTemperatureAndEnable(
                    Math.round((6500 - v * 4500) / 100) * 100)
            }

            Tui.TuiText {
                text: "warm"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        // ─── Spacer ─────────────────────────────────────────────────
        Item { Layout.fillHeight: true }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: "-/+ dim  0/9 min/max  e eye  [/] temp"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
        }
    }
}
