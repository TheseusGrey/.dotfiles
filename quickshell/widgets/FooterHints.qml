import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// Footer key hints — the bottom strip of the TUI frame.
// Content is context-aware:
//   - idle: the primary SUPER+ shortcut group, keyed under one [SUPER] label
//   - right panel open / finder open: hints for the active context
// Rendered as a horizontal row of compact `[key] label` chips. The row is
// clipped and should stay under a handful of chips to fit every width.
Item {
    id: root

    // ─── Idle: primary SUPER+ group (curated from hyprland.lua) ─────
    readonly property var superGroup: [
        { key: "space", label: "launcher" },
        { key: "t",     label: "terminal" },
        { key: "b",     label: "browser" },
        { key: "e",     label: "files" },
        { key: "w",     label: "close" },
        { key: "s",     label: "screenshot" },
        { key: "c",     label: "controls" },
        { key: "1-9",   label: "workspaces" }
    ]

    // ─── Per-context hint sets (right panel / finder) ────────────────
    readonly property var contextHints: ({
        "volume": [
            { key: "scroll",  label: "adjust" },
            { key: "click",   label: "switch device" },
            { key: "esc",     label: "close" }
        ],
        "brightness": [
            { key: "scroll",  label: "adjust" },
            { key: "esc",     label: "close" }
        ],
        "wifi": [
            { key: "click",   label: "connect" },
            { key: "esc",     label: "close" }
        ],
        "bluetooth": [
            { key: "click",   label: "pair" },
            { key: "esc",     label: "close" }
        ],
        "power": [
            { key: "click",   label: "action" },
            { key: "esc",     label: "close" }
        ],
        "notifications": [
            { key: "click",   label: "dismiss" },
            { key: "esc",     label: "close" }
        ],
        "keybinds": [
            { key: "scroll",  label: "navigate" },
            { key: "esc",     label: "close" }
        ],
        "menu": [
            { key: "click",   label: "open" },
            { key: "esc",     label: "close" }
        ]
    })

    // Which hint set is showing: empty → SUPER group.
    readonly property var activeHints: {
        if (PanelState.finderVisible) {
            return [
                { key: "type",  label: "filter" },
                { key: "enter", label: "launch" },
                { key: "esc",   label: "close" }
            ];
        }
        if (PanelState.rightPanelContext !== "") {
            return root.contextHints[PanelState.rightPanelContext] || [];
        }
        return [];
    }

    readonly property bool showingSuperGroup: root.activeHints.length === 0

    RowLayout {
        anchors.fill: parent
        spacing: Tui.TuiMetrics.cellWidth * 0.75
        clip: true

        // ─── SUPER group: shared [SUPER] label + inline entries ───────
        RowLayout {
            visible: root.showingSuperGroup
            spacing: Tui.TuiMetrics.cellWidth * 0.75

            Tui.TuiKeyHint {
                key: "SUPER"
                label: ""
            }

            Repeater {
                model: root.superGroup

                RowLayout {
                    required property var modelData
                    spacing: Tui.TuiMetrics.cellWidth * 0.4

                    Tui.TuiText {
                        text: modelData.key
                        textColor: Theme.accent
                        variant: "small"
                        font.bold: true
                    }

                    Tui.TuiText {
                        text: "·"
                        textColor: Theme.border
                        variant: "small"
                    }

                    Tui.TuiText {
                        text: modelData.label
                        textColor: Theme.textMuted
                        variant: "small"
                    }
                }
            }
        }

        // ─── Active context: plain chip row ────────────────────────────
        Repeater {
            visible: !root.showingSuperGroup
            model: root.activeHints

            Tui.TuiKeyHint {
                required property var modelData
                key: modelData.key
                label: modelData.label
            }
        }
    }
}