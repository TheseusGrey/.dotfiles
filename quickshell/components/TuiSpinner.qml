import QtQuick
import qs.services

// Animated spinner using Braille dot frames.
// Cycles through Unicode Braille patterns for a smooth rotation effect.
//
// Usage:
//   TuiSpinner { running: true }

Text {
    id: root

    property bool running: false
    property int interval: 80  // ms per frame
    property color spinnerColor: Theme.accent

    // Braille spinner frames (smooth rotation)
    readonly property var frames: [
        "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"
    ]

    property int frameIndex: 0

    text: running ? frames[frameIndex] : ""
    color: spinnerColor
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter

    Timer {
        running: root.running
        interval: root.interval
        repeat: true
        onTriggered: {
            root.frameIndex = (root.frameIndex + 1) % root.frames.length;
        }
    }
}
