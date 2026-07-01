import QtQuick
import Quickshell
import qs.services

// Date widget — shows the current date. Uses SystemClock for minute-precision updates.
// Format: "ddd, MMM dd" (e.g., "Wed, Jul 01")
// Colored in accent to complement the bold clock.
Text {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd, MMM dd")
    color: Theme.accentSecondary
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
}
