import QtQuick
import qs.services
import qs.components as Tui

// Renders a blocky rectangular border (radius 0) with an optional title chip
// that sits on the top border line.
//
// Visual result:
//   ┌──── title ─────────┐
//   │ content here        │
//   └─────────────────────┘
//
// Each edge is drawn as its own rect so panels that sit next to another
// surface can suppress the shared edge (e.g. left/right panels hide their top
// edge where it meets the top bar).
//
// The title is a bg-colored chip drawn over the top line so it reads like a
// terminal section header.

Item {
    id: root

    property string title: ""
    property color borderColor: Theme.border
    property color titleColor: Theme.titleColor
    property color bgColor: Theme.bg
    property int borderWidth: Theme.borderWidth
    property int contentPadding: Theme.panelPadding
    property bool titleBold: true

    // Per-edge visibility (suppress edges shared with a neighbor surface).
    property bool borderTop: true
    property bool borderBottom: true
    property bool borderLeft: true
    property bool borderRight: true

    default property alias content: contentArea.data

    // ─── Edges ───────────────────────────────────────────────────────
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.borderWidth
        color: root.borderColor
        visible: root.borderTop
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.borderWidth
        color: root.borderColor
        visible: root.borderBottom
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.borderWidth
        color: root.borderColor
        visible: root.borderLeft
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.borderWidth
        color: root.borderColor
        visible: root.borderRight
    }

    // Title chip breaks the top border line (bg-colored) when a title is set.
    Rectangle {
        id: titleChip
        visible: root.title !== ""
        radius: 0
        color: root.bgColor
        x: root.borderWidth + Tui.TuiMetrics.cellWidth
        height: titleText.implicitHeight
        width: titleText.implicitWidth + Tui.TuiMetrics.cellWidth * 2
        z: 1

        Tui.TuiText {
            id: titleText
            anchors.centerIn: parent
            text: root.title
            textColor: root.titleColor
            font.bold: root.titleBold
        }
    }

    // ─── Content area ───────────────────────────────────────────────
    // Margins only account for edges that are actually drawn.
    Item {
        id: contentArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: titleChip.visible ? titleChip.bottom : parent.top
        anchors.topMargin: titleChip.visible ? 0
            : (root.borderTop ? root.borderWidth : 0) + root.contentPadding
        anchors.leftMargin: (root.borderLeft ? root.borderWidth : 0) + root.contentPadding
        anchors.rightMargin: (root.borderRight ? root.borderWidth : 0) + root.contentPadding
        anchors.bottomMargin: (root.borderBottom ? root.borderWidth : 0) + root.contentPadding
    }
}