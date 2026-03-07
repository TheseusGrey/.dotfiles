import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config

PanelWindow {
    anchors {
        left: true
        top: true
        bottom: true
    }

    width: Appearance.inactiveSize

    exclusionMode: ExclusionMode.Normal

    Row {
        anchors.centerIn: parent
        spacing: 16

    }
}
