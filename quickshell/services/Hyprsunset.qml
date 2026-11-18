pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Software display control backed by hyprsunset.
//
// Desktops usually have no backlight device, so brightnessctl cannot dim the
// panel. hyprsunset exposes a gamma multiplier (100% = untouched) that dims the
// whole output, plus a colour temperature for eye protection. Both are applied
// through hyprctl and persist independently, so they compose:
//
//   gamma 60 + temperature 3000 -> dim and warm
//   gamma 60 + identity         -> dim only
//
// State lives in settings.json so it survives panel teardown, quickshell
// restarts and the brightness keybind script.
Singleton {
    id: root

    readonly property string qsh: Quickshell.env("HOME") + "/.local/bin/qsh"

    // 1..100; gamma is the matching 10..100% multiplier.
    property int brightness: 100
    property bool eyeEnabled: false
    // 2000..6500 K; lower is warmer.
    property int temperature: 3000

    readonly property int gamma: Math.round(10 + root.brightness * 0.9)

    function clampBrightness(value) {
        const n = Number(value);
        if (isNaN(n)) return 100;
        return Math.max(1, Math.min(100, Math.round(n)));
    }

    function clampTemperature(value) {
        const n = Number(value);
        if (isNaN(n)) return 3000;
        return Math.max(2000, Math.min(6500, Math.round(n / 100) * 100));
    }

    // Re-read persisted state. Called on startup and whenever the brightness
    // panel opens, so changes made by the keybind script are picked up.
    // The load is deferred: a Process started directly from a singleton's
    // Component.onCompleted never launches in this quickshell version.
    function reload() {
        loadTimer.restart();
    }

    function setBrightness(value) {
        const next = root.clampBrightness(value);
        if (next === root.brightness) return;
        root.brightness = next;
        root.persist("display.brightness", next);
        root.apply();
    }

    function setEyeEnabled(value) {
        const next = !!value;
        if (next === root.eyeEnabled) return;
        root.eyeEnabled = next;
        root.persist("display.eyeEnabled", next ? "true" : "false");
        root.apply();
    }

    function toggleEye() {
        root.setEyeEnabled(!root.eyeEnabled);
    }

    function setTemperature(value) {
        const next = root.clampTemperature(value);
        if (next === root.temperature) return;
        root.temperature = next;
        root.persist("display.eyeTemperature", next);
        if (root.eyeEnabled) root.apply();
    }

    // Adjusting the warmth is an implicit "turn it on" action: stopping at a
    // persisted-but-inactive temperature would look like the keys are dead.
    function setTemperatureAndEnable(value) {
        const next = root.clampTemperature(value);
        const enable = !root.eyeEnabled;
        if (next === root.temperature && !enable) return;
        root.temperature = next;
        root.eyeEnabled = true;
        root.persist("display.eyeTemperature", next);
        if (enable) root.persist("display.eyeEnabled", "true");
        root.apply();
    }

    function nudgeTemperature(delta) {
        root.setTemperatureAndEnable(root.temperature + delta);
    }

    // Apply both axes. hyprsunset keeps gamma while changing temperature and
    // keeps gamma while resetting to the identity matrix, so re-sending gamma
    // here only restores it after a daemon restart.
    function apply() {
        const colour = root.eyeEnabled
            ? "hyprctl hyprsunset temperature " + root.temperature
            : "hyprctl hyprsunset identity";
        Quickshell.execDetached(["sh", "-c",
            'exec 9>"${XDG_RUNTIME_DIR:-/tmp}/brightnesscontrol.lock"; flock 9; '
                + 'if ! hyprctl hyprsunset gamma >/dev/null 2>&1; then '
                + 'pkill -x hyprsunset >/dev/null 2>&1; sleep 0.2; '
                + 'setsid hyprsunset >/dev/null 2>&1 9>&- & sleep 0.4; fi; '
                + colour + " >/dev/null 2>&1; "
                + "hyprctl hyprsunset gamma " + root.gamma
        ]);
    }

    // ─── Persistence ────────────────────────────────────────────────
    // Slider drags emit many commits; coalesce writes into one qsh call.
    property var pending: ({})

    function persist(key, value) {
        root.pending[key] = String(value);
        saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 250
        repeat: false
        onTriggered: {
            const keys = Object.keys(root.pending);
            if (keys.length === 0) return;

            // One shell, sequential qsh calls: two detached settings writes
            // would race on the read-modify-write JSON file and lose a key.
            let cmd = 'exec 9>"${XDG_RUNTIME_DIR:-/tmp}/brightnesscontrol.lock"; flock 9; '
                + 'q="' + root.qsh + '"; ';
            for (let i = 0; i < keys.length; i++) {
                const key = keys[i];
                const value = String(root.pending[key]).replace(/'/g, "'\\''");
                cmd += '"$q" settings set ' + key + " '" + value + "'; ";
            }
            Quickshell.execDetached(["sh", "-c", cmd]);
            root.pending = ({});
        }
    }

    // The load is deferred: a Process started directly from a singleton's
    // Component.onCompleted never launches in this quickshell version.
    Timer {
        id: loadTimer
        interval: 100
        repeat: false
        onTriggered: loadProc.running = true
    }

    Process {
        id: loadProc
        command: ["sh", "-c",
            'q="$HOME/.local/bin/qsh"; '
            + 'printf "%s|%s|%s\\n" '
            + '"$("$q" settings get display.brightness)" '
            + '"$("$q" settings get display.eyeEnabled)" '
            + '"$("$q" settings get display.eyeTemperature)"']

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|");
                if (parts.length >= 3) {
                    if (parts[0] !== "") root.brightness = root.clampBrightness(parts[0]);
                    root.eyeEnabled = parts[1] === "true";
                    if (parts[2] !== "") root.temperature = root.clampTemperature(parts[2]);
                }
                root.apply();
            }
        }
    }

    Component.onCompleted: reload()
}
