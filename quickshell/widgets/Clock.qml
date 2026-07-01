import QtQuick
import Quickshell
import qs.services

// Clock widget — uses SystemClock for efficient updates.
// Displays time in HH:MM format. Color: textBright (prominent).
Text {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: Theme.textBright
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
    verticalAlignment: Text.AlignVCenter
}
