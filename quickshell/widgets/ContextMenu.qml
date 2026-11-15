import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// Context panel menu — the titled TuiList shown when the "menu" context is
// open (top bar ☰ button or the right rail glyph). Lists every available
// context; selecting one jumps the panel to that content in place.
//
// Keyboard: j/k (or arrows) move the cursor, enter opens it. The section
// letters from PanelKeys open a section directly.
Item {
    id: root

    readonly property var entries: PanelKeys.sections
    property int selectedIndex: 0

    function moveSelection(delta) {
        if (root.entries.length === 0) return;
        root.selectedIndex = (root.selectedIndex + delta + root.entries.length) % root.entries.length;
    }

    function activateSelected() {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.entries.length) return;
        PanelState.showRight(root.entries[root.selectedIndex].context);
    }

    function handlePanelAction(action, arg) {
        switch (action) {
            case "next":     root.moveSelection(1); return true;
            case "prev":     root.moveSelection(-1); return true;
            case "activate": root.activateSelected(); return true;
            case "open":     PanelState.showRight(arg); return true;
        }
        return false;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.itemSpacing

        Tui.TuiText {
            text: "choose a panel:"
            textColor: Theme.textMuted
            variant: "small"
        }

        Tui.TuiList {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                model: root.entries

                Tui.TuiMenuItem {
                    required property var modelData
                    required property int index

                    text: modelData.label
                    marker: index === root.selectedIndex ? ">" : " "
                    shortcut: modelData.key
                    bold: true
                    selected: index === root.selectedIndex
                    onClicked: {
                        root.selectedIndex = index;
                        PanelState.showRight(modelData.context);
                    }
                    Layout.fillWidth: true
                }
            }
        }

        Tui.TuiText {
            Layout.fillWidth: true
            text: "j/k move  enter open  tab section  esc close"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
