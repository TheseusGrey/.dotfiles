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

Item {
    id: root

    property real value: 0.0  // 0.0 to 1.0
    property int barLength: 10  // number of character cells
    property color filledColor: Theme.accent
    property color emptyColor: Theme.border

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
            const filled = Math.round(clamped * root.barLength);
            const empty = root.barLength - filled;

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
