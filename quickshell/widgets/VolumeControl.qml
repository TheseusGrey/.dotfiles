import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// Volume control panel — lists all PipeWire audio sinks and sources.
// Active devices are highlighted. Click to switch. Shows ▌░ progress bar.
// Uses wpctl for volume control and pactl for device enumeration.
// Includes both outputs (sinks) and inputs (sources/microphones).
// Virtual sources (e.g. EasyEffects) are shown alongside hardware mics.
// Monitor sources (loopback) are filtered out.
Item {
    id: root

    // ─── Output data model ───────────────────────────────────────────
    property var sinks: []
    property int defaultSinkId: -1
    property real defaultVolume: 0.0
    property bool defaultMuted: false

    // ─── Input data model ─────────────────────────────────────────────
    property var sources: []
    property int defaultSourceId: -1
    property real defaultInputVolume: 0.0
    property bool defaultInputMuted: false

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

    // ─── Source (input) enumeration ──────────────────────────────────
    Process {
        id: sourceListProc
        command: ["sh", "-c", "pactl -f json list sources 2>/dev/null"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                sourceListProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                try {
                    const parsed = JSON.parse(sourceListProc.buffer);
                    let result = [];
                    for (let i = 0; i < parsed.length; i++) {
                        const src = parsed[i];
                        const name = src.description || src.name || ("Source " + src.index);
                        const internalName = src.name || "";
                        // Filter out output monitor sources (loopback captures)
                        // These have "monitor" in the internal name or class is "monitor"
                        if (internalName.indexOf(".monitor") !== -1) continue;
                        if (src.monitor_source !== undefined && src.monitor_source !== "") continue;
                        // Keep everything else: hardware mics, virtual mics (EasyEffects, etc.)
                        result.push({
                            id: src.index,
                            name: name,
                            internalName: internalName,
                            volume: src.volume ? Math.round((src.volume["front-left"]?.value_percent || 0)) : 0,
                            muted: src.mute || false
                        });
                    }
                    root.sources = result;
                } catch (e) {
                    root.sources = [{
                        id: 0,
                        name: "Default Input",
                        internalName: "",
                        volume: Math.round(root.defaultInputVolume * 100),
                        muted: root.defaultInputMuted
                    }];
                }
                sourceListProc.buffer = "";
                sourceRefreshTimer.start();
            }
        }
    }

    Timer {
        id: sourceRefreshTimer
        interval: 5000
        repeat: false
        onTriggered: sourceListProc.running = true
    }

    // ─── Default source volume polling ───────────────────────────────
    Process {
        id: inputVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                root.defaultInputMuted = data.indexOf("[MUTED]") !== -1;
                const match = data.match(/Volume:\s+([\d.]+)/);
                if (match) root.defaultInputVolume = parseFloat(match[1]);
            }
        }

        onRunningChanged: {
            if (!running) inputVolPollTimer.start();
        }
    }

    Timer {
        id: inputVolPollTimer
        interval: 500
        repeat: false
        onTriggered: inputVolProc.running = true
    }

    // ─── Default source ID detection ─────────────────────────────────
    Process {
        id: defaultSourceProc
        command: ["sh", "-c", "pactl get-default-source 2>/dev/null"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const name = data.trim();
                if (name === "") return;
                for (let i = 0; i < root.sources.length; i++) {
                    if (root.sources[i].name === name || root.sources[i].internalName === name) {
                        root.defaultSourceId = root.sources[i].id;
                        return;
                    }
                }
                if (root.sources.length > 0) root.defaultSourceId = root.sources[0].id;
            }
        }

        onRunningChanged: {
            if (!running) defaultSourcePollTimer.start();
        }
    }

    Timer {
        id: defaultSourcePollTimer
        interval: 3000
        repeat: false
        onTriggered: defaultSourceProc.running = true
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

    // ─── Input volume adjustment commands ────────────────────────────
    function setInputVolume(percent) {
        const clamped = Math.max(0, Math.min(100, percent));
        root.defaultInputVolume = clamped / 100.0;
        cmdProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", clamped + "%"];
        cmdProc.running = true;
    }

    function toggleInputMute() {
        root.defaultInputMuted = !root.defaultInputMuted;
        cmdProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
        cmdProc.running = true;
    }

    function setSource(sourceId) {
        cmdProc.command = ["wpctl", "set-default", sourceId.toString()];
        cmdProc.running = true;
        sourceRefreshTimer.interval = 500;
        sourceRefreshTimer.start();
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
                Layout.fillWidth: true
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
                    text: {
                        const name = modelData.name;
                        const maxLen = 28;
                        return name.length > maxLen ? name.substring(0, maxLen - 1) + "…" : name;
                    }
                    active: modelData.id === root.defaultSinkId
                    activeColor: Theme.nord7
                    onClicked: root.setSink(modelData.id)
                    Layout.fillWidth: true
                }
            }
        }

        // ─── Input separator ─────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: Theme.boxHorizontal.repeat(40)
            textColor: Theme.border
        }

        // ─── Input volume display ────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tui.TuiText {
                text: root.defaultInputMuted ? "󰍭" : "󰍬"
                textColor: root.defaultInputMuted ? Theme.textMuted : Theme.nord9
                font.pixelSize: Theme.fontSizeLarge
            }

            // Input volume progress bar
            Tui.TuiProgress {
                Layout.fillWidth: true
                value: root.defaultInputVolume
                filledColor: root.defaultInputMuted ? Theme.textMuted : Theme.nord9
            }

            Tui.TuiText {
                text: Math.round(root.defaultInputVolume * 100) + "%"
                textColor: root.defaultInputMuted ? Theme.textMuted : Theme.textPrimary
            }

            // Scroll wheel adjustment for input
            MouseArea {
                Layout.fillWidth: true
                propagateComposedEvents: true
                onWheel: wheel => {
                    const delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    const newVol = Math.max(0, Math.min(100, Math.round(root.defaultInputVolume * 100) + delta));
                    root.setInputVolume(newVol);
                }
            }
        }

        // ─── Input controls row ──────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.itemSpacing

            Tui.TuiButton {
                text: "[-]"
                onClicked: {
                    const newVol = Math.max(0, Math.round(root.defaultInputVolume * 100) - 5);
                    root.setInputVolume(newVol);
                }
            }

            Tui.TuiButton {
                text: root.defaultInputMuted ? "[unmute]" : "[mute]"
                activeColor: Theme.nord9
                active: root.defaultInputMuted
                onClicked: root.toggleInputMute()
            }

            Tui.TuiButton {
                text: "[+]"
                onClicked: {
                    const newVol = Math.min(100, Math.round(root.defaultInputVolume * 100) + 5);
                    root.setInputVolume(newVol);
                }
            }
        }

        // ─── Source list header ──────────────────────────────────────
        Tui.TuiText {
            text: "inputs"
            textColor: Theme.textPrimary
            font.bold: true
        }

        // ─── Source list ─────────────────────────────────────────────
        Repeater {
            model: root.sources

            RowLayout {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: 6

                // Tree glyph
                Tui.TuiText {
                    text: index === root.sources.length - 1 ? Theme.treeEnd : Theme.treeBranch
                    textColor: Theme.accentSecondary
                }

                // Source name (clickable to switch)
                Tui.TuiButton {
                    text: {
                        const name = modelData.name;
                        const maxLen = 28;
                        return name.length > maxLen ? name.substring(0, maxLen - 1) + "…" : name;
                    }
                    active: modelData.id === root.defaultSourceId
                    activeColor: Theme.nord9
                    onClicked: root.setSource(modelData.id)
                    Layout.fillWidth: true
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
