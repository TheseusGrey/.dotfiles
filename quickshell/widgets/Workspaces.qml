import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.theme

RowLayout {
    spacing: 6

    Repeater {
        model: 10

        Rectangle {
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: Hyprland.focusedMonitor?.activeWorkspace?.id === wsId
            readonly property bool occupied: {
                for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                    let ws = Hyprland.workspaces.values[i];
                    if (ws.id === wsId && ws.windows > 0) return true;
                }
                return false;
            }

            width: 20
            height: 20
            radius: Theme.borderRounding
            color: active ? Theme.accent : occupied ? Theme.bgAlt : "transparent"
            border.color: active ? Theme.accent : Theme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: parent.wsId
                color: parent.active ? Theme.bg : Theme.fgDim
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
            }
        }
    }
}
