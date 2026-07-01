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
                                text: Theme.boxTopLeft + Theme.boxHorizontal + " " + modelData.title + " "
                                textColor: Theme.border
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Tui.TuiText {
                                Layout.fillWidth: true
                                property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)))
                                text: Theme.boxHorizontal.repeat(charWidth) + Theme.boxTopRight
                                textColor: Theme.border
                                font.pixelSize: Theme.fontSizeSmall
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

                                // Description (muted)
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
            text: "scroll:navigate  esc:close"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
