import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Left rail — west edge of the TUI frame.
// Always visible as a collapsed glyph rail; expands on hover.
// Frame chrome is the blocky rect border (TuiPanel); collapsed state is the
// glyph rail, expanded state holds the sectioned context content.
PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.bottom: true

    implicitWidth: PanelState.leftExpanded ? Theme.leftPanelExpanded : Theme.leftPanelCollapsed
    exclusiveZone: PanelState.leftExpanded ? Theme.leftPanelExpanded : Theme.leftPanelCollapsed
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-left"

    // No width animation: the panel snaps open/closed. A gliding width makes
    // the footer strip (which shares the bottom corners and stacks above us)
    // look like it is playing catch-up, with misaligned borders mid-slide.
    // No Behavior on implicitWidth.

    // ─── Hover detection for expand/collapse ───
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

    Timer {
        id: expandTimer
        interval: 150
        onTriggered: PanelState.leftExpanded = true
    }

    Timer {
        id: collapseTimer
        interval: 300
        onTriggered: {
            if (!panelHover.hovered) {
                PanelState.leftExpanded = false;
            }
        }
    }

    // ─── Rail-driven scroll to a section ─────────────────────────────
    // Rail glyphs set `target` ("workspaces" | "date" | "system" | "media").
    // Once the panel is expanded the section y is stable, so we scroll after
    // the content has had one frame to lay out.
    Timer {
        id: scrollTimer
        interval: Theme.animDuration + 60
        repeat: false
        property real targetY: 0
        onTriggered: expandedFlickable.contentY = targetY
    }

    function scrollToSection(target) {
        const section = target === "workspaces" ? workspacesSection
            : target === "date" ? dateSection
            : target === "system" ? systemSection
            : (target === "media" && mediaPlayer.hasPlayer) ? mediaPlayer
            : null;
        if (section === null) return;
        scrollTimer.targetY = section.y;
        scrollTimer.start();
    }

    // ─── Frame chrome (bg + blocky border) ────────────────────────────
    // Top edge suppressed: the top bar already draws the line at the corner.
    // Left edge suppressed: display edge (open frame), bottom edge is covered
    // by the opaque footer strip anyway.
    Tui.TuiPanel {
        anchors.fill: parent
        borderTop: false
        borderLeft: false
        borderBottom: false
    }

    // ─── Collapsed state: glyph rail (overlays chrome, full width) ────
    Tui.TuiRail {
        visible: !PanelState.leftExpanded
        anchors.fill: parent
        anchors.margins: Theme.borderWidth
        model: collapsedRailModel
        onActivated: item => {
            if (typeof item === "object" && item.target !== undefined) {
                PanelState.leftExpanded = true;
                root.scrollToSection(item.target);
            }
        }
    }

    // ─── Expanded state ───
    Flickable {
        id: expandedFlickable
        visible: PanelState.leftExpanded
        anchors.fill: parent
        anchors.leftMargin: Theme.borderWidth + Theme.panelPadding
        anchors.rightMargin: Theme.borderWidth + Theme.panelPadding
        anchors.topMargin: Theme.borderWidth + Theme.panelPadding
        anchors.bottomMargin: Theme.borderWidth + Theme.panelPadding
        contentHeight: expandedLayout.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: expandedLayout
            width: expandedFlickable.width
            spacing: Theme.itemSpacing

            // ─── Section: Workspaces ───
            Tui.TuiSection {
                id: workspacesSection
                title: "workspaces"
                Layout.fillWidth: true
            }

            Widgets.WorkspaceList {
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }

            Tui.TuiRule {
                Layout.fillWidth: true
                Layout.topMargin: Theme.itemSpacing
                Layout.bottomMargin: Theme.itemSpacing
            }

            // ─── Section: Calendar ───
            Tui.TuiSection {
                id: dateSection
                title: "date"
                Layout.fillWidth: true
            }

            Widgets.Calendar {
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }

            Tui.TuiRule {
                Layout.fillWidth: true
                Layout.topMargin: Theme.itemSpacing
                Layout.bottomMargin: Theme.itemSpacing
            }

            // ─── Section: System ───
            Tui.TuiSection {
                id: systemSection
                title: "system"
                Layout.fillWidth: true
            }

            Widgets.SystemStats {
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }

            Tui.TuiRule {
                visible: mediaPlayer.hasPlayer
                Layout.fillWidth: true
                Layout.topMargin: Theme.itemSpacing
                Layout.bottomMargin: Theme.itemSpacing
            }

            // ─── Section: Media (only if active) ───
            Widgets.MediaPlayer {
                id: mediaPlayer
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }

            Item {
                Layout.preferredHeight: Theme.panelPadding
            }
        }
    }

    // Model for the collapsed rail glyphs (status sections that expand in place).
    readonly property var collapsedRailModel: [
        { glyph: "󰪤", active: false, target: "workspaces" },
        { glyph: "󰃰", active: false, target: "date" },
        { glyph: "󰓅", active: false, target: "system" },
        { glyph: "󰝚", active: mediaPlayer.hasPlayer, target: "media" }
    ]
}