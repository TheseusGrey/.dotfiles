import QtQuick
import qs.services

// Base text component — monospace, themed, with explicit variants.
// All text in the shell should use this instead of raw Text {}.
//
// Variants: "small" | "body" | "large" | "icon"
// body is the default. `fontSize` (if set > 0) overrides the variant size,
// and callers may set `font.pixelSize` directly for one-off sizes.
Text {
    property color textColor: Theme.textPrimary
    property string variant: "body"
    property int fontSize: 0
    property bool monospace: true

    readonly property int _pixelSize: {
        if (root.fontSize > 0) return root.fontSize;
        switch (root.variant) {
            case "small": return Theme.fontSizeSmall;
            case "large": return Theme.fontSizeLarge;
            case "icon": return Theme.fontSizeIcon;
            default: return Theme.fontSize;
        }
    }

    id: root

    color: textColor
    font.family: Theme.fontFamily
    font.pixelSize: root._pixelSize
    verticalAlignment: Text.AlignVCenter
}