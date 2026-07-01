import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// Volume control panel — lists all PipeWire audio sinks.
// Active sink is highlighted. Click to switch. Shows ▌░ progress bar.
// Uses wpctl for volume control and pactl for sink enumeration.
Item {
    id: root

    // ─── Data model ──────────────────────────────────────────────────
    property var sinks: []
    property int defaultSinkId: -1
    property real defaultVolume: 0.0
    property bool defaultMuted: false

    // ─── Sink enumeration ────────────────────────────────────────────
    Process {
        id: sinkListProc
        command: ["sh", "-c", "pactl -f json list sinks 2>/dev/null || wpctl status"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                sinkListProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                // Parse accumulated output
                try {
                    const parsed = JSON.parse(sinkListProc.buffer);
                    let result = [];
                    for (let i = 0; i < parsed.length; i++) {
                        const sink = parsed[i];
                        result.push({
                            id: sink.index,
                            name: sink.description || sink.name || ("Sink " + sink.index),
                            internalName: sink.name || "",
                            volume: sink.volume ? Math.round((sink.volume["front-left"]?.value_percent || 0)) : 0,
                            muted: sink.mute || false
                        });
                    }
                    root.sinks = result;
                } catch (e) {
                    // Fallback: just show default sink
                    root.sinks = [{
                        id: 0,
                        name: "Default Output",
                        volume: Math.round(root.defaultVolume * 100),
                        muted: root.defaultMuted
                    }];
                }
                sinkListProc.buffer = "";
                refreshTimer.start();
            }
        }
    }

    // ─── Default sink volume polling ─────────────────────────────────
    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                root.defaultMuted = data.indexOf("[MUTED]") !== -1;
                const match = data.match(/Volume:\s+([\d.]+)/);
                if (match) root.defaultVolume = parseFloat(match[1]);
            }
        }

        onRunningChanged: {
            if (!running) volPollTimer.start();
        }
    }

    Timer {
        id: volPollTimer
        interval: 500
        repeat: false
        onTriggered: volProc.running = true
    }

    // ─── Default sink ID detection ───────────────────────────────────
    // `pactl -f json get-default-sink` returns the default sink name,
    // but simpler: parse `pactl get-default-sink` for the sink name,
    // then match against enumerated sinks.
    Process {
        id: defaultSinkProc
        command: ["sh", "-c", "pactl get-default-sink 2>/dev/null"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const name = data.trim();
                if (name === "") return;
                // Match against known sinks by name
                for (let i = 0; i < root.sinks.length; i++) {
                    if (root.sinks[i].name === name || root.sinks[i].internalName === name) {
                        root.defaultSinkId = root.sinks[i].id;
                        return;
                    }
                }
                // If no match by name, just use first sink
                if (root.sinks.length > 0) root.defaultSinkId = root.sinks[0].id;
            }
        }

        onRunningChanged: {
            if (!running) defaultSinkPollTimer.start();
        }
    }

    Timer {
        id: defaultSinkPollTimer
        interval: 3000
        repeat: false
        onTriggered: defaultSinkProc.running = true
    }

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: false
        onTriggered: sinkListProc.running = true
    }

    // Start enumeration when panel becomes visible
    Component.onCompleted: {
        sinkListProc.running = true;
    }

    // ─── Volume adjustment commands ──────────────────────────────────
    Process {
        id: cmdProc
        running: false
    }

    function setVolume(percent) {
        const clamped = Math.max(0, Math.min(100, percent));
        // Optimistic UI update — don't wait for next poll
        root.defaultVolume = clamped / 100.0;
        cmdProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", clamped + "%"];
        cmdProc.running = true;
    }

    function toggleMute() {
        // Optimistic UI update
        root.defaultMuted = !root.defaultMuted;
        cmdProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
        cmdProc.running = true;
    }

    function setSink(sinkId) {
        cmdProc.command = ["wpctl", "set-default", sinkId.toString()];
        cmdProc.running = true;
        // Refresh after switch
        refreshTimer.interval = 500;
        refreshTimer.start();
    }

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.itemSpacing

        // ─── Current volume display ──────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tui.TuiText {
                text: root.defaultMuted ? "󰖁" : root.defaultVolume > 0.66 ? "󰕾" : root.defaultVolume > 0.33 ? "󰖀" : "󰕿"
                textColor: root.defaultMuted ? Theme.textMuted : Theme.nord7
                font.pixelSize: Theme.fontSizeLarge
            }

            // Volume progress bar
            Tui.TuiProgress {
                Layout.fillWidth: true
                value: root.defaultVolume
                filledColor: root.defaultMuted ? Theme.textMuted : Theme.nord7
            }

            Tui.TuiText {
                text: Math.round(root.defaultVolume * 100) + "%"
                textColor: root.defaultMuted ? Theme.textMuted : Theme.textPrimary
            }

            // Scroll wheel adjustment overlay
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onWheel: wheel => {
                    const delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    const newVol = Math.max(0, Math.min(100, Math.round(root.defaultVolume * 100) + delta));
                    root.setVolume(newVol);
                }
            }
        }

        // ─── Controls row ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.itemSpacing

            Tui.TuiButton {
                text: "[-]"
                onClicked: {
                    const newVol = Math.max(0, Math.round(root.defaultVolume * 100) - 5);
                    root.setVolume(newVol);
                }
            }

            Tui.TuiButton {
                text: root.defaultMuted ? "[unmute]" : "[mute]"
                activeColor: Theme.nord7
                active: root.defaultMuted
                onClicked: root.toggleMute()
            }

            Tui.TuiButton {
                text: "[+]"
                onClicked: {
                    const newVol = Math.min(100, Math.round(root.defaultVolume * 100) + 5);
                    root.setVolume(newVol);
                }
            }
        }

        // ─── Separator ───────────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: Theme.boxHorizontal.repeat(40)
            textColor: Theme.border
        }

        // ─── Sink list ───────────────────────────────────────────────
        Tui.TuiText {
            text: "outputs"
            textColor: Theme.textPrimary
            font.bold: true
        }

        Repeater {
            model: root.sinks

            RowLayout {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: 6

                // Tree glyph
                Tui.TuiText {
                    text: index === root.sinks.length - 1 ? Theme.treeEnd : Theme.treeBranch
                    textColor: Theme.accentSecondary
                }

                // Sink name (clickable to switch)
                Tui.TuiButton {
                    text: modelData.name
                    active: modelData.id === root.defaultSinkId
                    activeColor: Theme.nord7
                    onClicked: root.setSink(modelData.id)
                    Layout.fillWidth: true
                }
            }
        }

        // ─── Spacer ─────────────────────────────────────────────────
        Item { Layout.fillHeight: true }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: "scroll:adjust  click:switch sink"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
