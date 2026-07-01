import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components as Tui

// Keybind cheat-sheet — displays configured keyboard shortcuts in a TUI table.
// Grouped by category with separators. Scrollable.
//
// Key names shown in accent color (bold), descriptions in muted.
// Edit the keybinds list below to match your hyprland.conf bindings.
Item {
    id: root

    // ─── Keybind data ────────────────────────────────────────────────
    // Each group: { title: string, binds: [{key, desc}] }
    readonly property var groups: [
        {
            title: "navigation",
            binds: [
                { key: "super+1..9", desc: "switch workspace" },
                { key: "super+shift+1..9", desc: "move to workspace" },
                { key: "super+tab", desc: "last workspace" },
                { key: "super+scroll", desc: "cycle workspaces" }
            ]
        },
        {
            title: "windows",
            binds: [
                { key: "super+q", desc: "close window" },
                { key: "super+f", desc: "fullscreen" },
                { key: "super+shift+f", desc: "fake fullscreen" },
                { key: "super+v", desc: "toggle float" },
                { key: "super+hjkl", desc: "move focus" },
                { key: "super+shift+hjkl", desc: "move window" },
                { key: "super+ctrl+hjkl", desc: "resize" }
            ]
        },
        {
            title: "shell",
            binds: [
                { key: "super+space", desc: "finder" },
                { key: "super+n", desc: "notifications" },
                { key: "super+b", desc: "brightness" },
                { key: "super+p", desc: "power menu" },
                { key: "super+l", desc: "lock screen" },
                { key: "super+escape", desc: "close panel" }
            ]
        },
        {
            title: "apps",
            binds: [
                { key: "super+return", desc: "terminal" },
                { key: "super+e", desc: "file manager" },
                { key: "super+w", desc: "browser" },
                { key: "super+shift+s", desc: "screenshot" }
            ]
        },
        {
            title: "media",
            binds: [
                { key: "XF86AudioRaise", desc: "volume up" },
                { key: "XF86AudioLower", desc: "volume down" },
                { key: "XF86AudioMute", desc: "toggle mute" },
                { key: "XF86MonBrightnessUp", desc: "brightness up" },
                { key: "XF86MonBrightnessDown", desc: "brightness down" }
            ]
        }
    ]

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Scrollable content
        Flickable {
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
                            text: "├" + Theme.boxHorizontal.repeat(30) + "┤"
                            textColor: Theme.border
                            font.pixelSize: Theme.fontSizeSmall
                            Layout.topMargin: 4
                        }

                        // ─── Group title ─────────────────────────────
                        Tui.TuiText {
                            text: Theme.boxTopLeft + Theme.boxHorizontal + " " + modelData.title + " " + Theme.boxHorizontal.repeat(Math.max(0, 26 - modelData.title.length)) + Theme.boxTopRight
                            textColor: Theme.border
                            font.pixelSize: Theme.fontSizeSmall
                            Layout.bottomMargin: 2
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
                                    Layout.preferredWidth: 140
                                    horizontalAlignment: Text.AlignRight
                                }

                                // Separator dot
                                Text {
                                    text: "·"
                                    color: Theme.border
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                // Description (muted)
                                Text {
                                    text: modelData.desc
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // Bottom cap
                Tui.TuiText {
                    text: Theme.boxBottomLeft + Theme.boxHorizontal.repeat(30) + Theme.boxBottomRight
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
            text: "scroll:navigate  esc:close"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
