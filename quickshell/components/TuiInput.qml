import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// Single-line input with a block caret, used by Finder.
// No Qt native chrome: bg fill + prompt glyph + styled TextInput.

Item {
    id: root

    property string prompt: ">"
    property color promptColor: Theme.accent
    property color textColor: Theme.textPrimary
    property color caretColor: Theme.accent
    property color bgColor: Theme.bgElevated

    signal submitted(string text)
    signal cancelled()
    signal tabPressed()

    implicitHeight: row.implicitHeight + Tui.TuiMetrics.lineHeight * 0.5

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: root.bgColor
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Theme.panelPadding
        anchors.rightMargin: Theme.panelPadding
        spacing: Theme.itemSpacing

        Tui.TuiText {
            text: root.prompt
            textColor: root.promptColor
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            color: root.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            selectionColor: Theme.bgHover
            selectedTextColor: Theme.textBright
            activeFocusOnTab: false
            clip: true
            verticalAlignment: Text.AlignVCenter

            // Block caret via cursorDelegate
            cursorDelegate: Rectangle {
                width: Tui.TuiMetrics.cellWidth
                radius: 0
                color: root.caretColor
            }

            onAccepted: root.submitted(input.text)

            Keys.onEscapePressed: event => {
                event.accepted = true;
                root.cancelled();
            }

            Keys.onTabPressed: event => {
                event.accepted = true;
                root.tabPressed();
            }
        }
    }

    function focusAndClear() {
        input.text = "";
        input.forceActiveFocus();
    }

    function selectAll() {
        input.selectAll();
    }

    readonly property string inputText: input.text
}