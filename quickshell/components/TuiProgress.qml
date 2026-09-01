import QtQuick
import qs.services
import qs.components as Tui

// TUI-style progress bar using full/empty block characters.
// Cell width comes from TuiMetrics so joints align with other chrome.
// Renders like: █████░░░░░ (50%)

Item {
    id: root

    property real value: 0.0  // 0.0 to 1.0
    property int barLength: -1  // -1 = auto from width, >0 = fixed character count
    property color filledColor: Theme.accent
    property color emptyColor: Theme.border

    readonly property int effectiveBarLength: {
        if (root.barLength > 0) return root.barLength;
        return Math.max(2, Tui.TuiMetrics.colsFor(root.width));
    }

    implicitWidth: barText.implicitWidth
    implicitHeight: barText.implicitHeight

    Text {
        id: barText
        anchors.fill: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft

        textFormat: Text.RichText
        text: {
            const clamped = Math.max(0, Math.min(1, root.value));
            const len = root.effectiveBarLength;
            const filled = Math.round(clamped * len);
            const empty = len - filled;

            let result = "";
            if (filled > 0) {
                result += `<span style="color:${root.filledColor}">`;
                result += Theme.blockFull.repeat(filled);
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