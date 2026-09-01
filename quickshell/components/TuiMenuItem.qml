import QtQuick
import qs.services
import qs.components as Tui

// Single row in a tree-list (context panel menu).
// A group row shows ">" with bold text; a child row shows "-" indented.
// The selected row renders inverse (accent background, dark text).
//
// Usage:
//   TuiMenuItem {
//       marker: ">"
//       text: "File Actions"
//       bold: true
//   }
//   TuiMenuItem {
//       indent: 1
//       text: "Rename"
//       selected: true
//       onClicked: ...
//   }

Item {
    id: root

    property string text: ""
    property string marker: ""     // ">" group, "-" child, "" none
    property int indent: 0         // cells of extra left padding
    property bool bold: false
    property bool selected: false
    property bool enabled: true
    property color normalColor: Theme.textPrimary
    property color markerColor: Theme.accentSecondary
    property color selectedFg: Theme.onAccent

    signal clicked()

    implicitHeight: Tui.TuiMetrics.lineHeight

    // Inverse block for the selected row.
    Rectangle {
        anchors.fill: parent
        radius: 0
        color: root.selected ? Theme.accent : (mouse.containsMouse ? Theme.bgHover : "transparent")
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.indent * Tui.TuiMetrics.cellWidth
        spacing: Tui.TuiMetrics.cellWidth

        Tui.TuiText {
            visible: root.marker !== ""
            text: root.marker
            textColor: root.selected ? root.selectedFg : root.markerColor
            font.bold: root.bold
            font.pixelSize: Theme.fontSize
        }

        Tui.TuiText {
            id: label
            text: root.text
            textColor: root.selected ? root.selectedFg
                : root.enabled ? root.normalColor : Theme.textMuted
            font.bold: root.bold
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}