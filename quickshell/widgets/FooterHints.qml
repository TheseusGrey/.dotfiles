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
        { key: "p",     label: "panel" },
        { key: "w",     label: "close" },
        { key: "s",     label: "screenshot" },
        { key: "c",     label: "controls" },
        { key: "1-9",   label: "workspaces" }
    ]

    // ─── Per-context hint sets (right panel / finder) ────────────────
    // Panel hints come from PanelKeys, the same map the dispatcher uses, so
    // the footer always describes keys that actually work.

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
            return PanelKeys.hintsFor(
                PanelState.rightPanelContext,
                PanelState.rightPanelCanGoBack
            );
        }
        return [];
    }

    readonly property bool showingSuperGroup: root.activeHints.length === 0

    RowLayout {
        id: topRow
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tui.TuiMetrics.cellWidth * 0.75
        clip: true

        // ─── SUPER group: shared [SUPER] chip + inline key·label ─────
        Tui.TuiKeyHint {
            visible: root.showingSuperGroup
            key: "SUPER"
            label: ""
        }

        // ─── Entries (both idle SUPER group and context states render
        //      through the same chip style: accent key · muted label).
        Repeater {
            model: root.showingSuperGroup ? root.superGroup : root.activeHints

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
}