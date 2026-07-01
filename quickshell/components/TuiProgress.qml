import QtQuick
import qs.services

// TUI-style progress bar using half-block and shade characters.
// Renders like: ▌▌▌▌▌░░░░░ (50%)
//
// Usage:
//   TuiProgress {
//       value: 0.65  // 0.0 to 1.0
//       width: 100
//   }
//
// When used with Layout.fillWidth: true, barLength is computed dynamically
// from the actual pixel width. Otherwise uses the fixed barLength property.

Item {
    id: root

    property real value: 0.0  // 0.0 to 1.0
    property int barLength: -1  // -1 = auto from width, >0 = fixed character count
    property color filledColor: Theme.accent
    property color emptyColor: Theme.border

    // Compute effective bar length: auto-derive from pixel width, or use fixed
    readonly property int effectiveBarLength: {
        if (root.barLength > 0) return root.barLength;
        // Estimate characters that fit in current width
        const charWidth = Theme.fontSize * 0.6;  // approximate monospace char width
        return Math.max(4, Math.floor(root.width / charWidth));
    }

    implicitWidth: barText.implicitWidth
    implicitHeight: barText.implicitHeight

    Text {
        id: barText
        anchors.fill: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        verticalAlignment: Text.AlignVCenter

        // Build the bar as rich text for per-character coloring
        textFormat: Text.RichText
        text: {
            const clamped = Math.max(0, Math.min(1, root.value));
            const len = root.effectiveBarLength;
            const filled = Math.round(clamped * len);
            const empty = len - filled;

            let result = "";
            if (filled > 0) {
                result += `<span style="color:${root.filledColor}">`;
                result += Theme.blockHalf.repeat(filled);
                result += "</span>";
            }
            if (empty > 0) {
                result += `<span style="color:${root.emptyColor}">`;
                result += Theme.blockEmpty.repeat(empty);
                result += "</span>";
            }
            return result;
        }
    }
}
