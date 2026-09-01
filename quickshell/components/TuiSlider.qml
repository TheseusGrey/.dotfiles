import QtQuick
import qs.services
import qs.components as Tui

// TuiSlider — block progress bar that is click/drag adjustable over 0..1.
// Uses TuiProgress for rendering and a MouseArea for interaction.
//
// Usage:
//   TuiSlider {
//       value: 0.65
//       onValueChanged: ...
//   }

Item {
    id: root

    property real value: 0.0
    property color filledColor: Theme.accent
    property color emptyColor: Theme.border
    property int barLength: -1
    property bool liveDrag: true   // update value during drag (else on release)

    signal valueCommitted(real v)

    implicitHeight: Tui.TuiMetrics.lineHeight
    implicitWidth: barText.implicitWidth

    Tui.TuiProgress {
        id: barText
        anchors.fill: parent
        value: root.value
        filledColor: root.filledColor
        emptyColor: root.emptyColor
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
            const b = (root.barLength > 0)
                ? root.barLength * Tui.TuiMetrics.cellWidth
                : w;
            const local = Math.max(0, Math.min(x, b));
            return Math.max(0, Math.min(1, local / w));
        }

        onPressed: event => {
            if (!root.liveDrag) {
                root.value = mouse.valueFromX(event.x);
            } else {
                root.value = mouse.valueFromX(event.x);
                root.valueCommitted(root.value);
            }
        }

        onPositionChanged: event => {
            if (mouse.pressed && root.liveDrag) {
                root.value = mouse.valueFromX(event.x);
                root.valueCommitted(root.value);
            }
        }

        onReleased: event => {
            if (!root.liveDrag) {
                root.valueCommitted(root.value);
            }
        }

        onWheel: wheel => {
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.value = Math.max(0, Math.min(1, root.value + delta));
            root.valueCommitted(root.value);
        }
    }
}