import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// Context panel menu — the titled TuiList shown when the "menu" context is
// open (top bar ☰ button or the right rail glyph). Lists every available
// context; selecting one jumps the panel to that content in place.
Item {
    id: root

    readonly property var entries: [
        { label: "volume",        context: "volume" },
        { label: "brightness",    context: "brightness" },
        { label: "network",       context: "wifi" },
        { label: "bluetooth",     context: "bluetooth" },
        { label: "notifications", context: "notifications" },
        { label: "keybinds",      context: "keybinds" },
        { label: "theme",         context: "theme" },
        { label: "power",         context: "power" }
    ]

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

                    text: modelData.label
                    marker: ">"
                    bold: true
                    selected: PanelState.rightPanelContext === modelData.context
                    onClicked: PanelState.openRight(modelData.context)
                    Layout.fillWidth: true
                }
            }
        }
    }
}