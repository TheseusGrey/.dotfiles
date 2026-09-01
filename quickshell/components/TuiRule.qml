import QtQuick
import qs.services
import qs.components as Tui

// Horizontal rule used to separate stacked sections.
// Draws a blocky rectangle line (not a glyph wall).
// Optional centered title chips sit on the line:  ── title ──

Item {
    id: root

    property string title: ""
    property color color: Theme.borderFaint
    property color titleColor: Theme.textMuted
    property bool titleBold: false

    // Line thickness in px. Keep it thin for internal separators.
    property int lineThickness: 1

    implicitHeight: root.title === "" ? root.lineThickness : Tui.TuiMetrics.lineHeight

    Rectangle {
        id: line
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.lineThickness
        color: root.color
    }

    // Title chip breaks the line (bg-colored) so it reads as a label.
    Rectangle {
        id: chip
        visible: root.title !== ""
        color: Theme.bg
        anchors.centerIn: parent
        height: chipText.implicitHeight
        width: chipText.implicitWidth + Tui.TuiMetrics.cellWidth * 2

        Tui.TuiText {
            id: chipText
            anchors.centerIn: parent
            text: root.title
            textColor: root.titleColor
            font.bold: root.titleBold
        }
    }
}