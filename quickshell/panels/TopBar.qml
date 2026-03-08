import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.widgets
import qs.config

PanelWindow {
    color: "transparent"
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Appearance.activeSize

    exclusionMode: ExclusionMode.Normal

    Rectangle {
      anchors.fill: parent
      // anchors.margins: 10
      color: "#2d2d2d"

      layer.enabled: true
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#a02a2a2a"
        shadowBlur: 0.6
        shadowVerticalOffset: 4
      }
    }

    Row {
        anchors.fill: parent
        spacing: 16

        Clock {
          anchors.centerIn: parent
        }
    }
}
