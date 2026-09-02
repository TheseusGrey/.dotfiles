import QtQuick
import qs.services
import qs.components as Tui

// TUI-style progress bar — sharp-cornered rect bar, cell-height aligned.
// Filled portion is a foreground Rectangle over a background Rectangle.
// barLength is kept for API compat but ignored (bar fills available width).

Item {
    id: root

    property real value: 0.0  // 0.0 to 1.0
    property int barLength: -1  // kept for API compat, unused
    property color filledColor: Theme.accent
    property color emptyColor: Theme.border

    implicitWidth: 100
    implicitHeight: Tui.TuiMetrics.lineHeight

    // Background track
    Rectangle {
        anchors.fill: parent
        radius: 0
        color: root.emptyColor
    }

    // Filled portion
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width * Math.max(0, Math.min(1, root.value))
        radius: 0
        color: root.filledColor
    }
}