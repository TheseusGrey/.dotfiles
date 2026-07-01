import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Top status bar — always visible, exclusive zone.
// Layout: ╭─ workspaces ─╮ │ window  ···  clock │ date ···  vol ⏻ 🔔 🔍 ─╯
//
// The bar uses a flat background with TUI separator characters between
// logical sections. Color is used for visual distinction:
//   - Workspace dots: accent (focused), primary (occupied), muted (empty)
//   - Window title: muted (secondary info)
//   - Clock: bright + bold (primary time)
//   - Date: accentSecondary (complement clock)
//   - Status icons: each has its own active color
PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: Theme.topPanelHeight
    exclusiveZone: Theme.topPanelHeight
    color: Theme.bg

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-top"

    // ─── Bottom border line (subtle separator from desktop) ────────
    WrapperRectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        leftMargin: 20

        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.panelPadding
        anchors.rightMargin: Theme.panelPadding
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        spacing: 0

        // ─── Left section: Workspaces + Window ─────────────────────
        RowLayout {
            Layout.fillHeight: true
            spacing: 6

            // Section open bracket
            Tui.TuiText {
                text: Theme.boxTopLeft + Theme.boxHorizontal
                textColor: Theme.border
                Layout.alignment: Qt.AlignVCenter
            }

            // Workspace dots
            Widgets.WorkspaceIndicator {
                Layout.alignment: Qt.AlignVCenter
            }

            // Separator between workspaces and window title
            Tui.TuiText {
                text: Theme.separator
                textColor: Theme.border
                Layout.alignment: Qt.AlignVCenter
            }

            // Active window title
            Widgets.ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
            }

            // Section close bracket
            Tui.TuiText {
                text: Theme.boxHorizontal + Theme.boxTopRight
                textColor: Theme.border
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ─── Flexible spacer ────────────────────────────────────────
        Item { Layout.fillWidth: true }

        // ─── Center section: Clock + Date ───────────────────────────
        RowLayout {
            Layout.fillHeight: true
            spacing: 6

            // Section open bracket
            Tui.TuiText {
                text: Theme.boxTopLeft + Theme.boxHorizontal
                textColor: Theme.border
                Layout.alignment: Qt.AlignVCenter
            }

            // Clock (bold, bright)
            Widgets.Clock {
                Layout.alignment: Qt.AlignVCenter
            }

            // Separator
            Tui.TuiText {
                text: Theme.separator
                textColor: Theme.border
                Layout.alignment: Qt.AlignVCenter
            }

            // Date (accent secondary)
            Widgets.DateWidget {
                Layout.alignment: Qt.AlignVCenter
            }

            // Section close bracket
            Tui.TuiText {
                text: Theme.boxHorizontal + Theme.boxTopRight
                textColor: Theme.border
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ─── Flexible spacer ────────────────────────────────────────
        Item { Layout.fillWidth: true }

        // ─── Right section: System controls ─────────────────────────
        RowLayout {
            Layout.fillHeight: true
            spacing: 6

            // Section open bracket
            Tui.TuiText {
                text: Theme.boxTopLeft + Theme.boxHorizontal
                textColor: Theme.border
                Layout.alignment: Qt.AlignVCenter
            }

            // Status icon buttons
            Widgets.StatusButtons {
                Layout.alignment: Qt.AlignVCenter
            }

            // Section close bracket
            Tui.TuiText {
                text: Theme.boxHorizontal + Theme.boxTopRight
                textColor: Theme.border
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
