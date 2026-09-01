import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// TuiKeyHint — a bracketed shortcut chip:  [SUPER+SPACE] finder
// Used in the footer and overlay help. Bracket chars are square and placed
// inside a bordered chip.

RowLayout {
    id: root

    property string key: ""
    property string label: ""
    property color bracketColor: Theme.border
    property color keyColor: Theme.textBright
    property color labelColor: Theme.textMuted

    spacing: Tui.TuiMetrics.cellWidth * 0.5

    // Bracket chip
    Row {
        Layout.alignment: Qt.AlignVCenter

        Tui.TuiText {
            text: "["
            textColor: root.bracketColor
            variant: "small"
        }

        Tui.TuiText {
            text: root.key
            textColor: root.keyColor
            variant: "small"
            font.bold: true
        }

        Tui.TuiText {
            text: "]"
            textColor: root.bracketColor
            variant: "small"
        }
    }

    Tui.TuiText {
        visible: root.label !== ""
        text: root.label
        textColor: root.labelColor
        variant: "small"
        Layout.alignment: Qt.AlignVCenter
        elide: Text.ElideRight
        Layout.maximumWidth: 160
    }
}