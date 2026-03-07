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

    // How tall the bar is (this one is bigger, as you wanted)
    height: Appearance.activeSize

    exclusionMode: ExclusionMode.Normal

    // Content goes here
    Row {
        anchors.fill: parent
        spacing: 16

        Clock {
          anchors.centerIn: parent
        }
    }
}
