pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.components as Components

RowLayout {
    property int activeWorkspace: HyprlandIpc.focusedMonitor?.activeWorkspace?.id ?? 0
    property int totalWorkspaces: HyprlandIpc.workspaces.length
    property string activeWindow: {
        const w = HyprlandIpc.focusedClient
        if (!w) return ""
        return (w.title !== "" ? w.title : w.class) ?? ""
    }


        spacing: 0

        Components.StyledText {
            text: {
                const ws  = `[ ${root.activeWorkspace}/${root.totalWorkspaces} ]`
                const win = root.activeWindow !== "" ? `  ${root.activeWindow}` : ""
                return ws + win
            }

            color: "#cdd6f4"
            font.family: "monospace"
            font.pixelSize: 13
            font.weight: Font.Medium
            renderType: Text.NativeRendering

            Layout.fillWidth: true
            elide: Text.ElideRight
        }
}

