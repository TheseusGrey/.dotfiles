import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Left panel — hover-to-expand sidebar.
//
// Collapsed (48px): minimal indicator glyph (⋮ or ◂) hinting expandable content.
// Expanded (300px): workspace tree, calendar, system stats, media player.
//
// Has exclusive zone for collapsed width so windows don't overlap.
//
PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.bottom: true

    margins.top: Theme.topPanelHeight

    implicitWidth: PanelState.leftExpanded ? Theme.leftPanelExpanded : Theme.leftPanelCollapsed
    exclusiveZone: PanelState.leftExpanded ? Theme.leftPanelExpanded : Theme.leftPanelCollapsed
    color: Theme.bg

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-left"

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Easing.OutCubic
        }
    }

    // ─── Hover detection for expand/collapse ───
    // HoverHandler doesn't get confused by child MouseAreas (unlike MouseArea.containsMouse).
    // It reports hover for the entire item bounds regardless of overlapping input handlers.
    HoverHandler {
        id: panelHover
        onHoveredChanged: {
            if (hovered) {
                collapseTimer.stop();
                expandTimer.start();
            } else {
                expandTimer.stop();
                collapseTimer.start();
            }
        }
    }

    // Small delay to prevent flicker on enter
    Timer {
        id: expandTimer
        interval: 150
        onTriggered: PanelState.leftExpanded = true
    }

    // Longer delay on leave so brief exits (e.g. tooltip) don't collapse
    Timer {
        id: collapseTimer
        interval: 300
        onTriggered: {
            if (!panelHover.hovered) {
                PanelState.leftExpanded = false;
            }
        }
    }

    // 1px right border
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Theme.border
    }

    // ─── Collapsed state ───
    Item {
        id: collapsedContent
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        visible: !PanelState.leftExpanded
        opacity: PanelState.leftExpanded ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration }
        }

        // Vertical hint indicators
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            // Expand hint glyph (arrow points right = expand direction)
            Tui.TuiText {
                text: "▸"
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeLarge
                Layout.alignment: Qt.AlignHCenter
            }

            // Small vertical dots for workspace count
            Repeater {
                model: Math.min(Hyprland.workspaces.values.length, 8)

                Tui.TuiText {
                    required property int index
                    text: Theme.dotSmall
                    textColor: index === 0 ? Theme.accent : Theme.textMuted
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // ─── Expanded state ───
    Item {
        id: expandedContent
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        anchors.rightMargin: Theme.panelPadding + 1  // account for border
        visible: PanelState.leftExpanded
        opacity: PanelState.leftExpanded ? 1 : 0
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration }
        }

        Flickable {
            id: flickable
            anchors.fill: parent
            contentHeight: expandedLayout.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: expandedLayout
                width: flickable.width
                spacing: Theme.itemSpacing

                // ─── Section: Workspaces ───
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Tui.TuiText {
                        text: "╭─ "
                        textColor: Theme.border
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Tui.TuiText {
                        text: "workspaces"
                        textColor: Theme.accentSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                    }
                    Tui.TuiText {
                        Layout.fillWidth: true
                        property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)))
                        text: " " + Theme.boxHorizontal.repeat(charWidth) + "╮"
                        textColor: Theme.border
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                Widgets.WorkspaceList {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                }

                // ─── Separator ───
                Tui.TuiText {
                    Layout.fillWidth: true
                    property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)) - 2)
                    text: "├" + Theme.boxHorizontal.repeat(charWidth) + "┤"
                    textColor: Theme.border
                    font.pixelSize: Theme.fontSizeSmall
                }

                // ─── Section: Calendar ───
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Tui.TuiText {
                        text: "╭─ "
                        textColor: Theme.border
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Tui.TuiText {
                        text: "calendar"
                        textColor: Theme.accentSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                    }
                    Tui.TuiText {
                        Layout.fillWidth: true
                        property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)))
                        text: " " + Theme.boxHorizontal.repeat(charWidth) + "╮"
                        textColor: Theme.border
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                Widgets.Calendar {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                }

                // ─── Separator ───
                Tui.TuiText {
                    Layout.fillWidth: true
                    property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)) - 2)
                    text: "├" + Theme.boxHorizontal.repeat(charWidth) + "┤"
                    textColor: Theme.border
                    font.pixelSize: Theme.fontSizeSmall
                }

                // ─── Section: System ───
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Tui.TuiText {
                        text: "╭─ "
                        textColor: Theme.border
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Tui.TuiText {
                        text: "system"
                        textColor: Theme.accentSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                    }
                    Tui.TuiText {
                        Layout.fillWidth: true
                        property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)))
                        text: " " + Theme.boxHorizontal.repeat(charWidth) + "╮"
                        textColor: Theme.border
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                Widgets.SystemStats {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                }

                // ─── Section: Media (only if active) ───
                Tui.TuiText {
                    visible: mediaPlayer.hasPlayer
                    Layout.fillWidth: true
                    property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)) - 2)
                    text: "├" + Theme.boxHorizontal.repeat(charWidth) + "┤"
                    textColor: Theme.border
                    font.pixelSize: Theme.fontSizeSmall
                }

                Widgets.MediaPlayer {
                    id: mediaPlayer
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                }

                // ─── Bottom cap ───
                Tui.TuiText {
                    Layout.fillWidth: true
                    property int charWidth: Math.max(1, Math.floor(width / (Theme.fontSizeSmall * 0.6)) - 2)
                    text: "╰" + Theme.boxHorizontal.repeat(charWidth) + "╯"
                    textColor: Theme.border
                    font.pixelSize: Theme.fontSizeSmall
                }

                // Spacer at bottom
                Item {
                    Layout.preferredHeight: Theme.panelPadding
                }
            }
        }
    }
}
