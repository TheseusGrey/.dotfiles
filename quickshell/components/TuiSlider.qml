import QtQuick
import qs.services
import qs.components as Tui

// TuiSlider — interactive progress bar adjustable via click, drag, or scroll.
// Wraps TuiProgress for rendering; MouseArea handles interaction.
// Hover dims the empty track to signal interactivity.
//
// Usage:
//   TuiSlider {
//       value: 0.65
//       onValueCommitted: v => { /* persist */ }
//   }

Item {
    id: root

    property real value: 0.0
    property color filledColor: Theme.accent
    property color emptyColor: Theme.border
    property int barLength: -1
    property bool liveDrag: true

    signal valueCommitted(real v)

    readonly property bool hovered: mouse.containsMouse

    implicitHeight: Tui.TuiMetrics.lineHeight
    implicitWidth: 100

    Tui.TuiProgress {
        anchors.fill: parent
        value: root.value
        filledColor: root.filledColor
        emptyColor: root.hovered ? Qt.lighter(root.emptyColor, 1.3) : root.emptyColor
        barLength: root.barLength
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function valueFromX(x) {
            const w = root.width;
            if (w <= 0) return 0;
            return Math.max(0, Math.min(1, x / w));
        }

        onPressed: event => {
            root.value = mouse.valueFromX(event.x);
            if (!root.liveDrag)
                root.valueCommitted(root.value);
        }

        onPositionChanged: event => {
            if (mouse.pressed && root.liveDrag) {
                root.value = mouse.valueFromX(event.x);
                root.valueCommitted(root.value);
            }
        }

        onReleased: {
            if (!root.liveDrag)
                root.valueCommitted(root.value);
        }

        onWheel: wheel => {
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.value = Math.max(0, Math.min(1, root.value + delta));
            root.valueCommitted(root.value);
        }
    }
}