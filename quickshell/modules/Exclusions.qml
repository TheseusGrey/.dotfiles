pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

Scope {
    id: root

    required property ShellScreen screen
    // required property Bar.BarWrapper bar

    ExclusionZone {
        anchors.left: true
    }

    ExclusionZone {
        anchors.right: true
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: ConfigTheme.navPanelSize
    }

    ExclusionZone {
        anchors.bottom: true
    }

    component ExclusionZone: PanelWindow {
        screen: root.screen
        // name: "border-exclusion"
        exclusiveZone: ConfigTheme.borderThickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
