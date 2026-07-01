import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.services

// Workspace dot indicator — shows ● for focused, • for occupied, ○ for empty.
// Only renders up to the highest occupied workspace ID.
RowLayout {
    id: root
    spacing: 4

    // Compute highest workspace ID that has windows or is active
    readonly property int highestWs: {
        let max = 1;
        for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
            let ws = Hyprland.workspaces.values[i];
            if (ws.id > 0 && ws.id > max) max = ws.id;
        }
        return max;
    }

    readonly property int focusedId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 0

    Repeater {
        model: root.highestWs

        Text {
            required property int index
            readonly property int wsId: index + 1
            readonly property bool focused: wsId === root.focusedId
            readonly property bool occupied: {
                for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                    let ws = Hyprland.workspaces.values[i];
                    if (ws.id === wsId) return true;
                }
                return false;
            }

            text: focused ? Theme.dotFilled : occupied ? Theme.dotSmall : Theme.dotEmpty
            color: focused ? Theme.accent : occupied ? Theme.textPrimary : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: focused

            Layout.alignment: Qt.AlignVCenter
        }
    }
}
