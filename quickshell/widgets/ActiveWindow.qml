import QtQuick
import Quickshell.Hyprland
import qs.services

// Active window title — shows the focused window's title, truncated to maxChars.
// Reuses the pattern from legacy: split on dash separators, take last segment.
// Colored in textMuted to be secondary to workspace indicator.
Text {
    id: root

    property int maxChars: 30

    readonly property string rawTitle: Hyprland.activeToplevel?.title ?? ""
    readonly property string displayTitle: {
        if (rawTitle === "") return "";
        // Split on common title separators (— or -) and take the last segment
        // This extracts the app name from titles like "file.txt — Neovim"
        const parts = rawTitle.split(/ [—\-] /);
        const name = parts[parts.length - 1].trim();
        if (name.length > maxChars) {
            return name.substring(0, maxChars - 1) + "…";
        }
        return name;
    }

    text: displayTitle
    color: Theme.textMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    elide: Text.ElideNone  // we handle truncation manually above
    maximumLineCount: 1
    verticalAlignment: Text.AlignVCenter
}
