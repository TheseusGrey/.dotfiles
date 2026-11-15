pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Central keyboard map for the right panel.
//
// Design:
//   - The panel owns the keyboard only while it is expanded (HyprlandFocusGrab
//     in RightPanel). Panel keys are therefore *bare* keys: no SUPER, no ALT.
//   - Hyprland keybinds are compositor-level and always win. The only real
//     conflict source is a global bind with no modifier and a single-character
//     key. `checkGlobalCollisions` warns when one appears.
//   - Keys are scoped by panel context. The same key may mean different things
//     in different panels; only the menu context carries the section letters.
//   - Dynamic lists use j/k + enter (and numbers where useful), never generated
//     letters, so device/notification churn cannot remap the keyboard.
//
// Widgets implement `handlePanelAction(action, arg)`. RightPanel does the
// routing and owns the global panel keys (esc / backspace / tab).

Singleton {
    id: root

    // ─── Sections ────────────────────────────────────────────────────
    // One source of truth for the collapsed rail, the context menu, the
    // section keymap, and the header labels.
    readonly property var sections: [
        { key: "v", label: "volume",        context: "volume",        glyph: "󰕾" },
        { key: "d", label: "brightness",    context: "brightness",    glyph: "󰃟" },
        { key: "w", label: "network",       context: "wifi",          glyph: "󰖩" },
        { key: "b", label: "bluetooth",     context: "bluetooth",     glyph: "󰂯" },
        { key: "n", label: "notifications", context: "notifications", glyph: "󰂚" },
        { key: "?", label: "keybinds",      context: "keybinds",      glyph: "⌨" },
        { key: "t", label: "theme",         context: "theme",         glyph: "◐" },
        { key: "p", label: "power",         context: "power",         glyph: "⏻" }
    ]

    function sectionFor(context) {
        for (let i = 0; i < root.sections.length; i++) {
            if (root.sections[i].context === context) return root.sections[i];
        }
        return null;
    }

    function titleFor(context) {
        if (context === "menu") return "menu";
        const section = root.sectionFor(context);
        return section ? section.label : context;
    }

    // ─── Global panel keys ───────────────────────────────────────────
    // Handled by RightPanel before the active widget sees the event.
    readonly property var globalKeys: [
        { key: "esc",       label: "close",   action: "close" },
        { key: "backspace", label: "back",    action: "back" },
        { key: "tab",       label: "section", action: "nextSection" },
        { key: "backtab",   label: "prev",    action: "prevSection", hint: false }
    ]

    // ─── Context keymaps ─────────────────────────────────────────────
    readonly property var menuKeys: root.sections.map(section => ({
        key: section.key,
        label: section.label,
        action: "open",
        arg: section.context
    })).concat([
        { key: "j",     label: "down",   action: "next" },
        { key: "k",     label: "up",     action: "prev" },
        { key: "down",  label: "down",   action: "next", hint: false },
        { key: "up",    label: "up",     action: "prev", hint: false },
        { key: "enter", label: "open",   action: "activate" }
    ])

    readonly property var contextKeys: ({
        "menu": root.menuKeys,

        "volume": [
            { key: "-", label: "vol -",    action: "outputDown" },
            { key: "+", label: "vol +",    action: "outputUp" },
            { key: "[", label: "mic -",    action: "inputDown" },
            { key: "]", label: "mic +",    action: "inputUp" },
            { key: "m", label: "mute",     action: "outputMute" },
            { key: "M", label: "mic mute", action: "inputMute" },
            { key: "o", label: "next out", action: "outputNext" },
            { key: "i", label: "next in",  action: "inputNext" }
        ],

        "brightness": [
            { key: "-", label: "dim",      action: "brightnessDown" },
            { key: "+", label: "bright",   action: "brightnessUp" },
            { key: "0", label: "min",      action: "brightnessMin" },
            { key: "9", label: "max",      action: "brightnessMax" },
            { key: "[", label: "prev dev", action: "devicePrev" },
            { key: "]", label: "next dev", action: "deviceNext" }
        ],

        "bluetooth": [
            { key: "j",     label: "down",   action: "next" },
            { key: "k",     label: "up",     action: "prev" },
            { key: "down",  label: "down",   action: "next", hint: false },
            { key: "up",    label: "up",     action: "prev", hint: false },
            { key: "enter", label: "toggle", action: "activate" },
            { key: "p",     label: "power",  action: "power" },
            { key: "s",     label: "scan",   action: "scan" }
        ],

        "notifications": [
            { key: "j",     label: "down",    action: "next" },
            { key: "k",     label: "up",      action: "prev" },
            { key: "down",  label: "down",    action: "next", hint: false },
            { key: "up",    label: "up",      action: "prev", hint: false },
            { key: "enter", label: "action",  action: "activate" },
            { key: "x",     label: "dismiss", action: "dismiss" },
            { key: "c",     label: "clear",   action: "clearAll" }
        ],

        "power": [
            { key: "j",     label: "down",     action: "next" },
            { key: "k",     label: "up",       action: "prev" },
            { key: "down",  label: "down",     action: "next", hint: false },
            { key: "up",    label: "up",       action: "prev", hint: false },
            { key: "enter", label: "run",      action: "activate" },
            { key: "l",     label: "lock",     action: "lock" },
            { key: "o",     label: "logout",   action: "logout" },
            { key: "r",     label: "reboot",   action: "reboot" },
            { key: "s",     label: "shutdown", action: "shutdown" }
        ]
    })

    // ─── Lookup ──────────────────────────────────────────────────────
    function actionFor(context, key) {
        const map = root.contextKeys[context] || [];
        for (let i = 0; i < map.length; i++) {
            if (map[i].key === key) return map[i];
        }
        return null;
    }

    function globalFor(key) {
        for (let i = 0; i < root.globalKeys.length; i++) {
            if (root.globalKeys[i].key === key) return root.globalKeys[i];
        }
        return null;
    }

    // Canonical token for a QML key event. Printable characters use
    // event.text so shifted chars (+, M, ?) work exactly as written in the
    // maps above. Special keys get stable names.
    function eventKey(event) {
        switch (event.key) {
            case Qt.Key_Escape:    return "esc";
            case Qt.Key_Return:
            case Qt.Key_Enter:     return "enter";
            case Qt.Key_Backspace: return "backspace";
            case Qt.Key_Tab:       return "tab";
            case Qt.Key_Backtab:   return "backtab";
            case Qt.Key_Up:        return "up";
            case Qt.Key_Down:      return "down";
            case Qt.Key_Left:      return "left";
            case Qt.Key_Right:     return "right";
            case Qt.Key_Space:     return "space";
            default:               break;
        }
        if (event.text && event.text.length === 1) return event.text;
        return "";
    }

    // ─── Hint bar data ───────────────────────────────────────────────
    // Same source as the dispatcher, so the footer can never drift from the
    // keys that actually work.
    function hintsFor(context, canGoBack) {
        let hints = [];
        const map = root.contextKeys[context] || [];
        for (let i = 0; i < map.length; i++) {
            if (map[i].hint !== false) hints.push({ key: map[i].key, label: map[i].label });
        }
        for (let i = 0; i < root.globalKeys.length; i++) {
            const g = root.globalKeys[i];
            if (g.hint === false) continue;
            if (g.action === "back" && !canGoBack) continue;
            hints.push({ key: g.key, label: g.label });
        }
        return hints;
    }

    // ─── Collision checks ────────────────────────────────────────────
    // Panel-local keys are only safe while no bare single-character bind
    // exists in Hyprland. Warn loudly if one shows up later.
    Process {
        id: bindProc
        command: ["hyprctl", "-j", "binds"]
        running: false

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => { bindProc.buffer += data + "\n"; }
        }

        onRunningChanged: {
            if (running) return;
            root.checkGlobalCollisions(bindProc.buffer);
            bindProc.buffer = "";
        }
    }

    Component.onCompleted: {
        root.validateLocalKeys();
        bindProc.running = true;
    }

    function validateLocalKeys() {
        const seenSections = {};
        for (let i = 0; i < root.sections.length; i++) {
            const key = root.sections[i].key;
            if (seenSections[key]) {
                console.warn("[PanelKeys] duplicate section key: " + key);
            }
            seenSections[key] = true;
        }

        for (const context in root.contextKeys) {
            const seen = {};
            const map = root.contextKeys[context];
            for (let i = 0; i < map.length; i++) {
                if (seen[map[i].key]) {
                    console.warn("[PanelKeys] duplicate key in " + context + ": " + map[i].key);
                }
                seen[map[i].key] = true;
            }
        }
    }

    function checkGlobalCollisions(json) {
        let binds = [];
        try {
            binds = JSON.parse(json);
        } catch (e) {
            return;
        }

        const panelKeys = {};
        for (const context in root.contextKeys) {
            const map = root.contextKeys[context];
            for (let i = 0; i < map.length; i++) panelKeys[map[i].key] = true;
        }
        for (let i = 0; i < root.globalKeys.length; i++) {
            panelKeys[root.globalKeys[i].key] = true;
        }

        for (let i = 0; i < binds.length; i++) {
            const bind = binds[i];
            const key = bind.key || "";
            if ((bind.modmask || 0) !== 0 || key.length !== 1) continue;
            if (panelKeys[key]) {
                console.warn("[PanelKeys] global bare bind conflicts with panel key '" + key + "'"
                    + (bind.description ? ": " + bind.description : ""));
            }
        }
    }
}
