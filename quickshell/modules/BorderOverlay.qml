import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components as Components

PanelWindow {
    id: borderWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "border-overlay"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Empty mask so clicks pass through entirely
    mask: Region {
        item: emptyItem
    }

    Item {
        id: emptyItem
        width: 0
        height: 0
    }

    // Border frame rendered as a stroked rounded rectangle
    // Shape {
    //     anchors.fill: parent
    //     layer.enabled: true
    //     layer.samples: 4
    //
    //     ShapePath {
    //         fillColor: "transparent"
    //         strokeColor: ConfigTheme.borderColor
    //         strokeWidth: ConfigTheme.borderThickness
    //
    //         startX: ConfigTheme.borderRounding + ConfigTheme.borderThickness / 2
    //         startY: ConfigTheme.borderThickness / 2
    //
    //         // Top edge
    //         PathLine {
    //             x: borderWindow.width - ConfigTheme.borderRounding - ConfigTheme.borderThickness / 2
    //             y: ConfigTheme.borderThickness / 2
    //         }
    //         // Top-right corner
    //         PathArc {
    //             x: borderWindow.width - ConfigTheme.borderThickness / 2
    //             y: ConfigTheme.borderRounding + ConfigTheme.borderThickness / 2
    //             radiusX: ConfigTheme.borderRounding
    //             radiusY: ConfigTheme.borderRounding
    //         }
    //         // Right edge
    //         PathLine {
    //             x: borderWindow.width - ConfigTheme.borderThickness / 2
    //             y: borderWindow.height - ConfigTheme.borderRounding - ConfigTheme.borderThickness / 2
    //         }
    //         // Bottom-right corner
    //         PathArc {
    //             x: borderWindow.width - ConfigTheme.borderRounding - ConfigTheme.borderThickness / 2
    //             y: borderWindow.height - ConfigTheme.borderThickness / 2
    //             radiusX: ConfigTheme.borderRounding
    //             radiusY: ConfigTheme.borderRounding
    //         }
    //         // Bottom edge
    //         PathLine {
    //             x: ConfigTheme.borderRounding + ConfigTheme.borderThickness / 2
    //             y: borderWindow.height - ConfigTheme.borderThickness / 2
    //         }
    //         // Bottom-left corner
    //         PathArc {
    //             x: ConfigTheme.borderThickness / 2
    //             y: borderWindow.height - ConfigTheme.borderRounding - ConfigTheme.borderThickness / 2
    //             radiusX: ConfigTheme.borderRounding
    //             radiusY: ConfigTheme.borderRounding
    //         }
    //         // Left edge
    //         PathLine {
    //             x: ConfigTheme.borderThickness / 2
    //             y: ConfigTheme.borderRounding + ConfigTheme.borderThickness / 2
    //         }
    //         // Top-left corner
    //         PathArc {
    //             x: ConfigTheme.borderRounding + ConfigTheme.borderThickness / 2
    //             y: ConfigTheme.borderThickness / 2
    //             radiusX: ConfigTheme.borderRounding
    //             radiusY: ConfigTheme.borderRounding
    //         }
    //     }
    // }

    PanelWindow {
        id: leftBorder
        anchors.top: true
        anchors.left: true
        anchors.bottom: true

        // implicitHeight: ConfigTheme.topPanelHeight
        implicitWidth: ConfigTheme.borderThickness
        exclusionMode: PanelWindow.ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: ConfigTheme.borderColor
        }
    }

    PanelWindow {
        id: rightBorder
        anchors.top: true
        anchors.right: true
        anchors.bottom: true

        implicitWidth: ConfigTheme.borderThickness
        exclusionMode: PanelWindow.ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: ConfigTheme.borderColor
        }
    }

    PanelWindow {
        id: topBorder
        anchors.top: true
        anchors.left: true
        anchors.right: true

        implicitHeight: ConfigTheme.navPanelSize
        exclusionMode: PanelWindow.ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: ConfigTheme.borderColor
        }

        Components.Bar {
            anchors.fill: parent
        }
    }


    PanelWindow {
        id: bottomBorder
        anchors.left: true
        anchors.right: true
        anchors.bottom: true

        implicitHeight: ConfigTheme.borderThickness
        exclusionMode: PanelWindow.ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: ConfigTheme.borderColor
        }
    }
}
