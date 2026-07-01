import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// Keybind cheat-sheet — dynamically reads keybinds from Hyprland at runtime.
// Uses `hyprctl -j binds` to always reflect the actual configuration.
// Groups binds by dispatcher category. Scrollable.
//
// Key names shown in accent color (bold), descriptions in muted.
Item {
    id: root

    // ─── Data model ──────────────────────────────────────────────────
    property var groups: []
    property bool loading: true

    // Modifier mask → text mapping
    readonly property var modMap: ({
        0: "",
        1: "shift",
        4: "ctrl",
        5: "shift+ctrl",
        8: "alt",
        9: "shift+alt",
        12: "ctrl+alt",
        13: "shift+ctrl+alt",
        64: "super",
        65: "super+shift",
        68: "super+ctrl",
        69: "super+shift+ctrl",
        72: "super+alt",
        73: "super+shift+alt",
        76: "super+ctrl+alt",
        77: "super+shift+ctrl+alt"
    })

    // Dispatcher → friendly category name
    readonly property var categoryMap: ({
        "exec": "apps & scripts",
        "workspace": "navigation",
        "movetoworkspace": "navigation",
        "movetoworkspacesilent": "navigation",
        "focusworkspaceoncurrentmonitor": "navigation",
        "movefocus": "windows",
        "movewindow": "windows",
        "resizeactive": "windows",
        "closewindow": "windows",
        "killactive": "windows",
        "togglefloating": "windows",
        "fullscreen": "windows",
        "fakefullscreen": "windows",
        "togglesplit": "windows",
        "moveactive": "windows",
        "pin": "windows",
        "changegroupactive": "windows",
        "togglegroup": "windows",
        "lockactivegroup": "windows",
        "moveintogroup": "windows",
        "moveoutofgroup": "windows",
        "movewindoworgroup": "windows",
        "mouse": "windows",
        "lockgroups": "windows"
    })

    // ─── Fetch keybinds from Hyprland ────────────────────────────────
    Process {
        id: bindProc
        command: ["hyprctl", "-j", "binds"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                bindProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                root.parseBinds(bindProc.buffer);
                bindProc.buffer = "";
                root.loading = false;
            }
        }
    }

    // ─── Parse JSON output ───────────────────────────────────────────
    function parseBinds(jsonStr) {
        try {
            const binds = JSON.parse(jsonStr);
            let categories = {};

            for (let i = 0; i < binds.length; i++) {
                const bind = binds[i];
                const modMask = bind.modmask || 0;
                const key = bind.key || (bind.keycode ? "code:" + bind.keycode : "");
                const dispatcher = (bind.dispatcher || "").toLowerCase();
                const arg = bind.arg || "";
                const desc = bind.description || "";

                if (key === "") continue;

                // Build key combo string
                const modStr = root.modMap[modMask] || ("mod" + modMask);
                const keyCombo = modStr !== "" ? modStr + "+" + key.toLowerCase() : key.toLowerCase();

                // Determine category
                let category = root.categoryMap[dispatcher] || "other";

                // Build description
                let description = desc;
                if (!description) {
                    if (dispatcher === "exec") {
                        // Clean up command for display
                        let cmd = arg;
                        cmd = cmd.replace(/^~\/.dotfiles\/bin\//, "");
                        cmd = cmd.replace(/^uwsm app -- /, "");
                        cmd = cmd.replace(/^~\/.local\/share\/omarchy\/bin\//, "");
                        // Truncate long commands
                        if (cmd.length > 30) cmd = cmd.substring(0, 29) + "…";
                        description = cmd;
                    } else if (dispatcher === "workspace" || dispatcher === "focusworkspaceoncurrentmonitor") {
                        description = "workspace " + arg;
                    } else if (dispatcher === "movetoworkspace" || dispatcher === "movetoworkspacesilent") {
                        description = "move to workspace " + arg;
                    } else if (dispatcher === "movefocus") {
                        description = "focus " + arg;
                    } else if (dispatcher === "movewindow") {
                        description = "move window " + arg;
                    } else if (dispatcher === "resizeactive") {
                        description = "resize " + arg;
                    } else if (dispatcher === "killactive" || dispatcher === "closewindow") {
                        description = "close window";
                    } else if (dispatcher === "togglefloating") {
                        description = "toggle float";
                    } else if (dispatcher === "fullscreen") {
                        description = "fullscreen";
                    } else if (dispatcher === "togglesplit") {
                        description = "toggle split";
                    } else {
                        description = dispatcher + (arg ? " " + arg : "");
                    }
                }

                // Skip mouse binds that are just move/resize drag
                if (key.startsWith("mouse:") && !desc) continue;

                if (!categories[category]) {
                    categories[category] = [];
                }
                categories[category].push({ key: keyCombo, desc: description });
            }

            // Convert to array of groups, ordered
            const order = ["navigation", "windows", "apps & scripts", "media", "other"];
            let result = [];
            for (let o = 0; o < order.length; o++) {
                const cat = order[o];
                if (categories[cat] && categories[cat].length > 0) {
                    result.push({ title: cat, binds: categories[cat] });
                }
            }
            // Add any remaining categories
            for (const cat in categories) {
                if (order.indexOf(cat) === -1 && categories[cat].length > 0) {
                    result.push({ title: cat, binds: categories[cat] });
                }
            }

            root.groups = result;
        } catch (e) {
            // Fallback: show error state
            root.groups = [{ title: "error", binds: [{ key: "—", desc: "failed to parse hyprctl binds" }] }];
        }
    }

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Loading state
        Tui.TuiText {
            visible: root.loading
            text: "loading keybinds..."
            textColor: Theme.textMuted
            font.italic: true
        }

        // Scrollable content
        Flickable {
            visible: !root.loading
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: keybindLayout.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: keybindLayout
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.groups

                    ColumnLayout {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        spacing: 2

                        // ─── Group separator (except first) ──────────
                        Tui.TuiText {
                            visible: index > 0
                            Layout.fillWidth: true
                            property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)) - 2)
                            text: "├" + Theme.boxHorizontal.repeat(charWidth) + "┤"
                            textColor: Theme.border
                            font.pixelSize: Theme.fontSizeSmall
                            Layout.topMargin: 4
                        }

                        // ─── Group title ─────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 2
                            spacing: 0

                            Tui.TuiText {
                                text: Theme.boxTopLeft + Theme.boxHorizontal + " "
                                textColor: Theme.border
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Tui.TuiText {
                                text: modelData.title
                                textColor: Theme.accentSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                            }
                            Tui.TuiText {
                                Layout.fillWidth: true
                                property int charWidth: Math.max(0, Math.floor(width / (Theme.fontSizeSmall * 0.6)) - 2)
                                text: " " + Theme.boxHorizontal.repeat(charWidth) + Theme.boxTopRight
                                textColor: Theme.border
                                font.pixelSize: Theme.fontSizeSmall
                                clip: true
                            }
                        }

                        // ─── Binds in this group ─────────────────────
                        Repeater {
                            model: modelData.binds

                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 4

                                // Key name (bold, accent)
                                Text {
                                    text: modelData.key
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.bold: true
                                    Layout.preferredWidth: 120
                                    Layout.maximumWidth: 130
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                }

                                // Separator dot
                                Text {
                                    text: "·"
                                    color: Theme.border
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                // Description
                                Text {
                                    text: modelData.desc
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // Bottom cap
                Tui.TuiText {
                    Layout.fillWidth: true
                    property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)) - 2)
                    text: Theme.boxBottomLeft + Theme.boxHorizontal.repeat(charWidth) + Theme.boxBottomRight
                    textColor: Theme.border
                    font.pixelSize: Theme.fontSizeSmall
                    Layout.topMargin: 4
                }

                // Spacer
                Item { Layout.preferredHeight: Theme.panelPadding }
            }
        }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: "scroll:navigate  esc:close  (from hyprctl binds)"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
