pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.services

Singleton {
    id: theme

    // ─── Semantic Color Roles ─────────────────────────────────────────
    // All colors come from generated Colors.qml (Matugen). Widgets must use
    // these roles, never the raw aliases below (aliases are transitional).
    readonly property color bg: Colors.bg
    readonly property color bgElevated: Colors.bgElevated
    readonly property color bgHover: Colors.bgHover
    readonly property color border: Colors.border
    readonly property color borderFaint: Colors.borderFaint
    readonly property color textPrimary: Colors.textPrimary
    readonly property color textBright: Colors.textBright
    readonly property color textContrast: Colors.bg
    readonly property color textMuted: Colors.textMuted
    readonly property color onAccent: Colors.accentFg
    readonly property color accent: Colors.accent
    readonly property color accentSecondary: Colors.accentSecondary
    readonly property color utility: Colors.utility
    readonly property color info: Colors.info
    readonly property color error: Colors.error
    readonly property color warning: Colors.warning
    readonly property color success: Colors.success
    readonly property color caution: Colors.caution

    // ─── Transitional aliases (replace with semantic roles in brick 4) ─
    readonly property color nord0: Colors.bg
    readonly property color nord1: Colors.bgElevated
    readonly property color nord2: Colors.bgHover
    readonly property color nord3: Colors.border
    readonly property color nord4: Colors.textPrimary
    readonly property color nord5: Colors.textBright
    readonly property color nord6: Colors.textBright
    readonly property color nord7: Colors.utility
    readonly property color nord8: Colors.accent
    readonly property color nord9: Colors.accentSecondary
    readonly property color nord10: Colors.accentSecondary
    readonly property color nord11: Colors.error
    readonly property color nord12: Colors.warning
    readonly property color nord13: Colors.caution
    readonly property color nord14: Colors.success
    readonly property color nord15: Colors.info

    // ─── Typography ──────────────────────────────────────────────────
    readonly property string fontFamily: "DepartureMono Nerd Font"
    readonly property string fontFamilyMono: "DepartureMono Nerd Font Mono"
    readonly property int fontSize: 18
    readonly property int fontSizeLarge: 24
    readonly property int fontSizeClock: 22
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeIcon: 24

    // ─── Chrome Geometry ─────────────────────────────────────────────
    readonly property int borderWidth: 4
    readonly property int topPanelHeight: 48
    readonly property int leftPanelCollapsed: 48
    readonly property int leftPanelExpanded: 300
    readonly property int rightPanelCollapsed: 48
    readonly property int rightPanelExpanded: 380
    readonly property int footerHeight: 48
    readonly property int panelPadding: 10
    readonly property int itemSpacing: 8

    // ─── TUI block metrics (measured at runtime by TuiMetrics) ────────
    readonly property real charWidth: -1   // set by TuiMetrics
    readonly property real lineHeight: -1  // set by TuiMetrics

    // ─── Animation ───────────────────────────────────────────────────
    readonly property int animDuration: 150
    readonly property int animDurationSlow: 300

    // ─── Human-readable section title default ─────────────────────
    readonly property color titleColor: Colors.textPrimary

    // ─── Notification urgency → accent color ─────────────────────────
    // Urgency levels use the semantic roles so every theme stays legible.
    function urgencyColor(urgency) {
        switch (urgency) {
            case NotificationUrgency.Low: return Theme.success
            case NotificationUrgency.Critical: return Theme.error
            default: return Theme.accent
        }
    }

    // ─── TUI Characters ──────────────────────────────────────────────
    // Box-drawing. Borders are drawn with Qt rects (blocky, no glyph walls);
    // these glyphs remain for inline separators and rules inside content.
    readonly property string boxTopLeft: "┏"
    readonly property string boxTopRight: "┓"
    readonly property string boxBottomLeft: "┗"
    readonly property string boxBottomRight: "┛"
    readonly property string boxHorizontal: "━"
    readonly property string boxVertical: "┃"
    readonly property string boxLeftConnector: "┣"
    readonly property string boxRightConnector: "┫"
    readonly property string boxTopConnector: "┳"
    readonly property string boxBottomConnector: "┻"

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