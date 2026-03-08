import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.widgets
import qs.config

PanelWindow {
    // Which screen edge to anchor to
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Appearance.activeSize

    exclusionMode: ExclusionMode.Normal

    Row {
        anchors.fill: parent
        spacing: 16

        Clock {
          anchors.centerIn: parent
        }
    }
}
