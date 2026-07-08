import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.services
import qs.components as Tui

// Expanded workspace list — tree-style with window titles and nerd font icons.
//
// Visual:
//   ● 1  Desktop
//     ├──  Firefox
//     └── 󰨞 VSCode
//   ○ 2  empty
//   • 3
//     └──  kitty
//
ColumnLayout {
    id: root
    spacing: 2

    // Map of WM_CLASS → nerd font icon
    // Common apps; falls back to  for unknown
    readonly property var appIcons: ({
        "firefox": "",
        "firefox-esr": "",
        "zen": "󰖟",
        "chromium": "",
        "google-chrome": "",
        "brave-browser": "󰖟",
        "com.github.wwmm.easyeffects": "",
        "code": "󰨞",
        "code-oss": "󰨞",
        "codium": "󰨞",
        "neovim": "",
        "nvim": "",
        "kitty": "",
        "alacritty": "",
        "foot": "",
        "wezterm": "",
        "thunar": "󰉋",
        "nautilus": "󰉋",
        "nemo": "󰉋",
        "dolphin": "󰉋",
        "spotify": "󰓇",
        "discord": "󰙯",
        "vesktop": "󰙯",
        "telegram-desktop": "",
        "signal": "󰍡",
        "slack": "󰒱",
        "obs": "󰑋",
        "gimp": "",
        "inkscape": "",
        "blender": "󰂫",
        "steam": "󰓓",
        "lutris": "󰊗",
        "pavucontrol": "󰕾",
        "easyeffects": "󰺢",
        "obsidian": "󰎛",
        "mpv": "󰕧",
        "vlc": "󰕼",
        "transmission-gtk": "󰇚",
        "qbittorrent": "󰇚",
        "org.gnome.Settings": "",
        "gnome-control-center": "",
        "libreoffice-startcenter": "󰈙",
        "libreoffice-writer": "󰈙",
        "xdg-desktop-portal": "󰀻"
    })

    function getIcon(appId: string): string {
        if (!appId) return "";
        // Try exact match
        const lower = appId.toLowerCase();
        if (root.appIcons[lower] !== undefined) return root.appIcons[lower];
        // Try partial match (class might have extra info)
        for (const key in root.appIcons) {
            if (lower.indexOf(key) !== -1) return root.appIcons[key];
        }
        return "";  // fallback generic window icon
    }

    Repeater {
        model: Hyprland.workspaces

        ColumnLayout {
            id: wsDelegate
            required property var modelData
            spacing: 0

            readonly property bool isFocused: Hyprland.focusedWorkspace === modelData
            readonly property var windows: modelData.toplevels.values
            readonly property int windowCount: windows.length
            readonly property bool hasWindows: windowCount > 0

            // Workspace header row: ● 1  name/status
            RowLayout {
                spacing: 4
                Layout.fillWidth: true

                // Status dot
                Tui.TuiText {
                    text: wsDelegate.isFocused ? Theme.dotFilled
                        : wsDelegate.hasWindows ? Theme.dotSmall
                        : Theme.dotEmpty
                    textColor: wsDelegate.isFocused ? Theme.accent
                             : wsDelegate.hasWindows ? Theme.textPrimary
                             : Theme.textMuted
                    font.bold: wsDelegate.isFocused
                }

                // Workspace ID
                Tui.TuiText {
                    text: wsDelegate.modelData.id.toString()
                    textColor: wsDelegate.isFocused ? Theme.accent : Theme.textPrimary
                    font.bold: wsDelegate.isFocused
                }

                // Window count or "empty"
                Tui.TuiText {
                    text: wsDelegate.hasWindows
                        ? `[${wsDelegate.windowCount}]`
                        : "empty"
                    textColor: Theme.textMuted
                    font.pixelSize: Theme.fontSizeSmall
                }

                // Click to switch workspace
                MouseArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onClicked: wsDelegate.modelData.activate()
                }
            }

            // Window tree (only shown if workspace has windows)
            Repeater {
                model: wsDelegate.windows

                RowLayout {
                    required property var modelData
                    required property int index
                    spacing: 4
                    Layout.leftMargin: 12

                    readonly property bool isLast: index === wsDelegate.windowCount - 1
                    readonly property string appClass: modelData.lastIpcObject?.class ?? ""
                    readonly property string windowAddress: modelData.lastIpcObject?.address ?? ""
                    readonly property string title: {
                        const t = modelData.title ?? "";
                        return t.length > 24 ? t.substring(0, 24) + "…" : t;
                    }

                    // Tree glyph
                    Tui.TuiText {
                        text: parent.isLast ? Theme.treeEnd : Theme.treeBranch
                        textColor: Theme.border
                    }

                    // App icon
                    Tui.TuiText {
                        text: root.getIcon(parent.appClass)
                        textColor: wsDelegate.isFocused ? Theme.accent : Theme.textPrimary
                    }

                    // Window title (clickable to focus)
                    Tui.TuiButton {
                        text: parent.title
                        textAlign: Text.AlignLeft
                        fontSize: Theme.fontSizeSmall
                        Layout.fillWidth: true
                        onClicked: {
                            if (parent.windowAddress !== "") {
                                Hyprland.dispatch("hl.dsp.focus({ window = 'address:" + parent.windowAddress + "' })")
                                // Hyprland.dispatch("focuswindow address:" + parent.windowAddress);
                            }
                        }
                    }
                }
            }
        }
    }
}
