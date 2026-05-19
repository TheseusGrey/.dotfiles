pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Colors
    readonly property string bg: data.colors?.bg ?? "#1e1e2e"
    readonly property string bgAlt: data.colors?.bgAlt ?? "#262637"
    readonly property string fg: data.colors?.fg ?? "#cdd6f4"
    readonly property string fgDim: data.colors?.fgDim ?? "#6c7086"
    readonly property string accent: data.colors?.accent ?? "#89b4fa"
    readonly property string accentAlt: data.colors?.accentAlt ?? "#74c7ec"
    readonly property string border: data.colors?.border ?? "#45475a"
    readonly property string shadow: data.colors?.shadow ?? "#11111b"
    readonly property string success: data.colors?.success ?? "#a6e3a1"
    readonly property string warning: data.colors?.warning ?? "#f9e2af"
    readonly property string error: data.colors?.error ?? "#f38ba8"

    // Font - monospace only for TUI aesthetic
    readonly property string fontFamily: data.font?.family ?? "JetBrainsMono Nerd Font"
    readonly property int fontSize: data.font?.size ?? 13
    readonly property int fontSizeLarge: data.font?.sizeLarge ?? 14
    readonly property int fontSizeSmall: data.font?.sizeSmall ?? 11

    // Border / geometry
    readonly property int borderThickness: data.border?.thickness ?? 2
    readonly property int borderRounding: data.border?.rounding ?? 0
    readonly property int expandedBarHeight: data.border?.expandedBarHeight ?? 36
    readonly property int expandedPanelWidth: data.border?.expandedPanelWidth ?? 380

    // Animation
    readonly property int animDuration: data.animation?.duration ?? 100

    // Exclusive zone
    readonly property bool exclusiveCollapsed: data.exclusiveZone?.collapsed ?? true
    readonly property bool exclusiveExpanded: data.exclusiveZone?.expanded ?? false

    property var data: ({})

    FileView {
        id: themeFile
        path: Qt.resolvedUrl("theme.json")
        watchChanges: true
        onTextChanged: {
            try {
                root.data = JSON.parse(text);
            } catch (e) {
                console.warn("Theme: failed to parse theme.json:", e);
            }
        }
    }
}
