import QtQuick
import qs.services

// A panel container that combines a background fill with TUI border chrome.
// Use this for bordered content areas within panels.
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
    property color titleColor: Theme.accent
    default property alias content: border.content

    Rectangle {
        anchors.fill: parent
        color: root.panelBg
    }

    TuiBorder {
        id: border
        anchors.fill: parent
        title: root.title
        borderColor: root.borderColor
        titleColor: root.titleColor
    }
}
