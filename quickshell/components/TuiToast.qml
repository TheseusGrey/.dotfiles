import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// TuiToast — a one-line bordered popup used by OSD and notification ticks.
// Same chrome language as panels (blocky rect border, bg fill) but compact.

Item {
    id: root

    property string text: ""
    property string subText: ""
    property color borderColor: Theme.border
    property color textColor: Theme.textPrimary
    property color subTextColor: Theme.textMuted

    implicitWidth: row.implicitWidth + Theme.borderWidth * 2 + Tui.TuiMetrics.cellWidth * 2
    implicitHeight: row.implicitHeight + Theme.borderWidth * 2 + Tui.TuiMetrics.lineHeight * 0.5

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Theme.bg
        border.color: root.borderColor
        border.width: Theme.borderWidth
    }

    ColumnLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Tui.TuiText {
            text: root.text
            textColor: root.textColor
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Tui.TuiText {
            visible: root.subText !== ""
            text: root.subText
            textColor: root.subTextColor
            variant: "small"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}