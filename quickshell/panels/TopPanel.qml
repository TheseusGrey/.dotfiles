import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Top status bar — top edge of the TUI frame.
// Layout: workspaces + title  ···  clock | date  ···  status buttons
// Frame chrome: single blocky 4px rect border (TuiPanel), no glyph walls.
PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: Theme.topPanelHeight
    exclusiveZone: Theme.topPanelHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-top"

    // ─── Frame chrome ────────────────────────────────────────────────
    Tui.TuiPanel {
        anchors.fill: parent
        // Open frame: the screen-side borders (top + the two outside
        // corners, drawn over by the side rails) are suppressed so the
        // shell meets the display edge without an outline.
        borderTop: false
        borderLeft: false
        borderRight: false
    }

    // ─── Content overlay ─────────────────────────────────────────────
    // Left/right margins match the side rails' own content inset
    // (Theme.borderWidth) so the top bar's outer sections line up with the
    // icons inside the collapsed left/right rails, not the rail frame edges.
    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.borderWidth + Theme.panelPadding
        anchors.rightMargin: Theme.borderWidth

        // ─── Left section: Workspaces + Window ─────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Widgets.WorkspaceIndicator {
                Layout.alignment: Qt.AlignVCenter
            }

            Tui.TuiText {
                text: Theme.separator
                textColor: Theme.borderFaint
                Layout.alignment: Qt.AlignVCenter
            }

            Widgets.ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ─── Center section: Clock + Date (always truly centered) ───
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: centerRow.implicitWidth
            height: centerRow.implicitHeight

            // Hovering the date+time opens the popup. Closing is owned by the
            // popup's own band (gap + popup) so this never races with it.
            HoverHandler {
                id: centerHover
                onHoveredChanged: {
                    if (hovered)
                        PanelState.datePopupVisible = true;
                }
            }

            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: 6

                Widgets.Clock {
                    Layout.alignment: Qt.AlignVCenter
                }

                Tui.TuiText {
                    text: Theme.separator
                    textColor: Theme.borderFaint
                    Layout.alignment: Qt.AlignVCenter
                }

                Widgets.DateWidget {
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // ─── Right section: System controls ─────────────────────────
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Widgets.StatusButtons {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
