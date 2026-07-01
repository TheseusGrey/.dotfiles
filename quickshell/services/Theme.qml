pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: theme

    // ─── Nord Palette ───────────────────────────────────────────────
    // Polar Night
    readonly property color nord0: "#2E3440"   // bg
    readonly property color nord1: "#3B4252"   // elevated surface
    readonly property color nord2: "#434C5E"   // selection / hover
    readonly property color nord3: "#4C566A"   // muted / borders

    // Snow Storm
    readonly property color nord4: "#D8DEE9"   // primary text
    readonly property color nord5: "#E5E9F0"   // bright text
    readonly property color nord6: "#ECEFF4"   // high-contrast text

    // Frost
    readonly property color nord7: "#8FBCBB"   // utility
    readonly property color nord8: "#88C0D0"   // accent primary
    readonly property color nord9: "#81A1C1"   // accent secondary
    readonly property color nord10: "#5E81AC"  // deep accent

    // Aurora
    readonly property color nord11: "#BF616A"  // error / danger
    readonly property color nord12: "#D08770"  // warning
    readonly property color nord13: "#EBCB8B"  // caution
    readonly property color nord14: "#A3BE8C"  // success
    readonly property color nord15: "#B48EAD"  // purple accent

    // ─── Semantic Aliases ────────────────────────────────────────────
    readonly property color bg: nord0
    readonly property color bgElevated: nord1
    readonly property color bgHover: nord2
    readonly property color border: nord3
    readonly property color textPrimary: nord4
    readonly property color textBright: nord5
    readonly property color textContrast: nord6
    readonly property color textMuted: nord3
    readonly property color accent: nord8
    readonly property color accentSecondary: nord9
    readonly property color error: nord11
    readonly property color warning: nord12
    readonly property color success: nord14

    // ─── Typography ──────────────────────────────────────────────────
    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"
    readonly property int fontSize: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeIcon: 16

    // ─── Geometry ────────────────────────────────────────────────────
    readonly property int topPanelHeight: 32
    readonly property int leftPanelCollapsed: 48
    readonly property int leftPanelExpanded: 300
    readonly property int rightPanelCollapsed: 48
    readonly property int rightPanelExpanded: 380
    readonly property int panelPadding: 8
    readonly property int itemSpacing: 8

    // ─── Animation ───────────────────────────────────────────────────
    readonly property int animDuration: 150
    readonly property int animDurationSlow: 300

    // ─── TUI Characters ──────────────────────────────────────────────
    // Box-drawing (rounded)
    readonly property string boxTopLeft: "╭"
    readonly property string boxTopRight: "╮"
    readonly property string boxBottomLeft: "╰"
    readonly property string boxBottomRight: "╯"
    readonly property string boxHorizontal: "─"
    readonly property string boxVertical: "│"

    // Block elements
    readonly property string blockFull: "█"
    readonly property string blockHalf: "▌"
    readonly property string blockEmpty: "░"

    // Indicators
    readonly property string dotFilled: "●"
    readonly property string dotEmpty: "○"
    readonly property string dotSmall: "•"

    // Tree glyphs
    readonly property string treeBranch: "├──"
    readonly property string treeEnd: "└──"
    readonly property string treePipe: "│"

    // Separators
    readonly property string separator: "│"
}
