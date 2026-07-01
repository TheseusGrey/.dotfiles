import QtQuick
import qs.services

// Base text component — monospace, themed, with sensible defaults.
// All text in the shell should use this instead of raw Text {}.
Text {
    // Allow callers to override color role
    property color textColor: Theme.textPrimary

    color: textColor
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
}
