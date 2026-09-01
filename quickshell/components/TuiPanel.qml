import QtQuick
import qs.services

// A panel container: solid background fill + blocky rectangular TUI border.
// Use this for any exclusive-zone surface or bordered content area.
//
// Usage:
//   TuiPanel {
//       title: "workspace"
//       TuiText { text: "hello" }
//   }

Item {
    id: root

    property string title: ""
    property color panelBg: Theme.bg
    property color borderColor: Theme.border
    property color titleColor: Theme.titleColor
    property int borderWidth: Theme.borderWidth

    // Per-edge visibility (suppress edges shared with a neighbor surface).
    property bool borderTop: true
    property bool borderBottom: true
    property bool borderLeft: true
    property bool borderRight: true

    default property alias content: border.content

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: root.panelBg
    }

    TuiBorder {
        id: border
        anchors.fill: parent
        title: root.title
        borderColor: root.borderColor
        titleColor: root.titleColor
        bgColor: root.panelBg
        borderWidth: root.borderWidth
        borderTop: root.borderTop
        borderBottom: root.borderBottom
        borderLeft: root.borderLeft
        borderRight: root.borderRight
    }
}