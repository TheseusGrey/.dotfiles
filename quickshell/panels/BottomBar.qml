import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config

PanelWindow {
    anchors {
        bottom: true
        left: true
        right: true
    }

    height: Appearance.inactiveSize

    exclusionMode: ExclusionMode.Normal

    Row {
        anchors.centerIn: parent
        spacing: 16

    }
}
