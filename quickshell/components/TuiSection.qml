import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// Section header + content block inside a panel.
// Title is bold in titleColor (textPrimary by default); accent is reserved
// for supplementary text elsewhere. An optional rule lines the section.
//
// Usage:
//   TuiSection {
//       title: "workspaces"
//       TuiText { text: "content" }
//   }

ColumnLayout {
    id: root

    property string title: ""
    property color titleColor: Theme.titleColor
    property color ruleColor: Theme.borderFaint
    property bool showRule: false
    property int contentSpacing: Theme.itemSpacing
    default property alias content: contentArea.data

    spacing: 0

    // ─── Title row ───────────────────────────────────────────────────
    Tui.TuiText {
        visible: root.title !== ""
        text: root.title
        textColor: root.titleColor
        font.bold: true
        Layout.bottomMargin: root.showRule ? Theme.itemSpacing * 0.5 : Theme.itemSpacing
        Layout.leftMargin: Tui.TuiMetrics.cellWidth
        Layout.alignment: Qt.AlignLeft
    }

    // ─── Optional rule ───────────────────────────────────────────────
    Tui.TuiRule {
        visible: root.showRule
        color: root.ruleColor
        Layout.fillWidth: true
        Layout.bottomMargin: Theme.itemSpacing
    }

    // ─── Content ─────────────────────────────────────────────────────
    ColumnLayout {
        id: contentArea
        Layout.fillWidth: true
        spacing: root.contentSpacing
    }
}