import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Right context panel — east edge of the TUI frame.
// Always visible as a narrow collapsed strip; expands with slide animation
// when a status icon is clicked. Content switches based on rightPanelContext.
// The panel shows an inside-the-border header text (context title) when expanded,
// mirroring the finder popup header style — no border-breaking title chip.
//
// While expanded the window spans the whole screen (transparent everywhere but
// the panel column) instead of just the 380px strip. This is what keeps
// keyboard focus on the panel: Hyprland re-runs its pointer hit test when a
// layer surface commits a keyboard-interactivity change, and refocuses the
// surface under the cursor. A pointer sitting over a window (or over the top
// bar) would otherwise take the keyboard away from the panel a few ms after it
// opened. With a full-screen surface the cursor is always over the panel, so
// the refocus is a no-op. The blank area doubles as the click-outside catcher;
// RightPanelZone keeps the frame's right edge reserved for layout.
PanelWindow {
    id: root

    anchors.right: true
    anchors.bottom: true

    readonly property bool isExpanded: PanelState.rightPanelContext !== ""

    readonly property string contextTitle: PanelKeys.titleFor(PanelState.rightPanelContext)

    // Expanded: cover the monitor so pointer hit-testing always lands on this
    // surface. Collapsed: just the rail, below the top bar.
    implicitWidth: root.isExpanded
        ? (root.screen ? root.screen.width : 1920)
        : Theme.rightPanelCollapsed
    implicitHeight: root.screen
        ? (root.isExpanded ? root.screen.height : root.screen.height - Theme.topPanelHeight)
        : 1080
    // The exclusive zone (frame layout) lives in RightPanelZone.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-right"

    // Take the keyboard while expanded. Changing to Exclusive makes Hyprland
    // focus this layer surface on commit; the collapsed rail stays out of the
    // way. Do not also set `focusable` — it writes the same property.
    WlrLayershell.keyboardFocus: isExpanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // No width animation: snap open/closed (same reason as the left panel —
    // prevents the footer strip from visually "playing catch-up" at the
    // shared bottom corner mid-slide). No Behavior on implicitWidth.

    // ─── Click outside to close ──────────────────────────────────────
    // Below the panel column, above everything on screen: the first click
    // anywhere outside the panel dismisses it.
    MouseArea {
        anchors.fill: parent
        enabled: root.isExpanded
        onClicked: PanelState.closeRight()
    }

    // ─── Keyboard navigation ──────────────────────────────────────────
    // The layer surface has exclusive keyboard focus while expanded; this
    // FocusScope turns that into panel navigation. All panel keys are bare
    // keys (no modifier). See PanelKeys.qml for the map and the collision check.
    //
    // Focus is retried for a short window after expansion/context changes:
    // a newly focused layer surface needs a compositor round-trip before it
    // reliably accepts keyboard focus (same pattern as Finder).
    property int keyFocusAttempts: 0

    function activeWidget() {
        switch (PanelState.rightPanelContext) {
            case "volume":        return volumeLoader.item;
            case "brightness":    return brightnessLoader.item;
            case "wifi":          return wifiLoader.item;
            case "bluetooth":     return bluetoothLoader.item;
            case "power":         return powerLoader.item;
            case "notifications": return notificationLoader.item;
            case "keybinds":      return keybindsLoader.item;
            case "menu":          return menuLoader.item;
            case "theme":         return themeLoader.item;
            default:              return null;
        }
    }

    // tab / shift+tab cycle through the section list.
    function moveSection(delta) {
        const sections = PanelKeys.sections;
        if (sections.length === 0) return;

        let index = -1;
        for (let i = 0; i < sections.length; i++) {
            if (sections[i].context === PanelState.rightPanelContext) {
                index = i;
                break;
            }
        }

        if (index === -1) {
            index = delta > 0 ? 0 : sections.length - 1;
        } else {
            index = (index + delta + sections.length) % sections.length;
        }
        PanelState.showRight(sections[index].context);
    }

    function handlePanelKey(event) {
        const key = PanelKeys.eventKey(event);
        if (key === "") return false;

        // Destructive power actions are one keystroke away. Swallow auto-repeat
        // for the power context so holding a key can never arm-and-confirm
        // reboot/shutdown in a single press.
        if (event.isAutoRepeat && PanelState.rightPanelContext === "power") return true;

        // In the power menu, esc cancels an armed action before closing.
        if (PanelState.rightPanelContext === "power" && key === "esc"
                && powerLoader.item && powerLoader.item.confirmIndex >= 0) {
            powerLoader.item.confirmIndex = -1;
            powerLoader.item.confirmRemaining = 0;
            return true;
        }

        // Global panel keys take precedence over the context map.
        const global = PanelKeys.globalFor(key);
        if (global) {
            switch (global.action) {
                case "close":
                    PanelState.closeRight();
                    return true;
                case "back":
                    if (PanelState.rightPanelCanGoBack) PanelState.goBackToMenu();
                    else PanelState.closeRight();
                    return true;
                case "nextSection":
                    root.moveSection(1);
                    return true;
                case "prevSection":
                    root.moveSection(-1);
                    return true;
            }
        }

        const widget = root.activeWidget();
        if (!widget || typeof widget.handlePanelAction !== "function") return false;

        const binding = PanelKeys.actionFor(PanelState.rightPanelContext, key);
        if (!binding) return false;

        return widget.handlePanelAction(binding.action, binding.arg) !== false;
    }

    FocusScope {
        id: keyHandler
        anchors.fill: parent
        focus: root.isExpanded

        Keys.onPressed: event => {
            if (root.handlePanelKey(event)) event.accepted = true;
        }
    }

    Timer {
        id: keyFocusTimer
        interval: 30
        repeat: true
        running: false
        onTriggered: {
            if (!root.isExpanded) {
                stop();
                return;
            }
            if (!keyHandler.activeFocus) keyHandler.forceActiveFocus();
            if (++root.keyFocusAttempts >= 20) stop();
        }
    }

    onIsExpandedChanged: {
        if (isExpanded) {
            root.keyFocusAttempts = 0;
            keyFocusTimer.restart();
        } else {
            keyFocusTimer.stop();
        }
    }

    Connections {
        target: PanelState
        function onRightPanelContextChanged() {
            if (!root.isExpanded) return;
            root.keyFocusAttempts = 0;
            keyFocusTimer.restart();
        }
    }

    // ─── Panel column ────────────────────────────────────────────────
    // The visible 48/380px column at the right edge. The expanded window
    // starts at the top of the monitor, so the column is inset below the top
    // bar; the collapsed window already starts below the top bar (its height is
    // shortened by the bar), so it must not be inset a second time.
    Item {
        id: body
        anchors.top: parent.top
        anchors.topMargin: root.isExpanded ? Theme.topPanelHeight : 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.isExpanded ? Theme.rightPanelExpanded : Theme.rightPanelCollapsed

        // Swallow clicks on blank panel space so they don't reach the
        // outside-click dismisser behind the column.
        MouseArea {
            anchors.fill: parent
        }

        // ─── Frame chrome (bg + blocky border) ─────────────────────────
        // Top edge suppressed: the top bar already draws the line at the corner.
        // Right edge suppressed: display edge (open frame), bottom edge is covered
        // by the opaque footer strip anyway.
        Tui.TuiPanel {
            anchors.fill: parent
            borderTop: false
            borderRight: false
            borderBottom: false
        }

        // ─── Collapsed state: icon hint strip ──────────────────────────
        Tui.TuiRail {
            visible: !root.isExpanded
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
            model: collapsedIconModel
            onActivated: item => {
                if (typeof item === "object" && item.target !== undefined) {
                    PanelState.openRight(item.target);
                }
            }
        }

        // ─── Expanded state: full content ──────────────────────────────
        Item {
            id: expandedContent
            visible: root.isExpanded
            anchors.fill: parent
            anchors.leftMargin: Theme.borderWidth + Theme.panelPadding
            anchors.rightMargin: Theme.borderWidth + Theme.panelPadding
            anchors.bottomMargin: Theme.borderWidth + Theme.panelPadding
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: Theme.borderWidth + Theme.panelPadding
                spacing: Theme.itemSpacing

                // ─── Header: title + (back to menu) button ─────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.itemSpacing

                    Tui.TuiText {
                        text: root.contextTitle
                        textColor: Theme.titleColor
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Tui.TuiButton {
                        text: "◀ back"
                        variant: "body"
                        width: Tui.TuiMetrics.cellWidth * 8
                        height: Tui.TuiMetrics.lineHeight + Theme.panelPadding
                        visible: PanelState.rightPanelCanGoBack
                        onClicked: PanelState.goBackToMenu()
                    }
                }

                // ─── Context content ──────────────────────────────────
                // Each context widget is created only when it is first opened.
                // Most of them poll external tools (wpctl, brightnessctl, nmcli,
                // ...) on construction; doing that for nine hidden panels at login
                // competed with shell startup and delayed the first launcher use.
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader { id: volumeLoader;        active: PanelState.rightPanelContext === "volume";        anchors.fill: parent; sourceComponent: volumeComponent }
                    Loader { id: brightnessLoader;    active: PanelState.rightPanelContext === "brightness";    anchors.fill: parent; sourceComponent: brightnessComponent }
                    Loader { id: wifiLoader;          active: PanelState.rightPanelContext === "wifi";          anchors.fill: parent; sourceComponent: wifiComponent }
                    Loader { id: bluetoothLoader;     active: PanelState.rightPanelContext === "bluetooth";     anchors.fill: parent; sourceComponent: bluetoothComponent }
                    Loader { id: powerLoader;         active: PanelState.rightPanelContext === "power";         anchors.fill: parent; sourceComponent: powerComponent }
                    Loader { id: notificationLoader;  active: PanelState.rightPanelContext === "notifications"; anchors.fill: parent; sourceComponent: notificationComponent }
                    Loader { id: keybindsLoader;      active: PanelState.rightPanelContext === "keybinds";      anchors.fill: parent; sourceComponent: keybindsComponent }
                    Loader { id: menuLoader;          active: PanelState.rightPanelContext === "menu";          anchors.fill: parent; sourceComponent: menuComponent }
                    Loader { id: themeLoader;         active: PanelState.rightPanelContext === "theme";         anchors.fill: parent; sourceComponent: themeComponent }
                }
            }
        }
    }

    // ─── Lazily instantiated context widgets ─────────────────────────
    // Referenced by the Loaders above; kept as Components so each widget is
    // only constructed the first time its context is opened.
    Component { id: volumeComponent;        Widgets.VolumeControl { anchors.fill: parent } }
    Component { id: brightnessComponent;    Widgets.BrightnessControl { anchors.fill: parent } }
    Component { id: wifiComponent;          Widgets.WiFiPanel { anchors.fill: parent } }
    Component { id: bluetoothComponent;     Widgets.BluetoothPanel { anchors.fill: parent } }
    Component { id: powerComponent;         Widgets.PowerMenu { anchors.fill: parent } }
    Component { id: notificationComponent;  Widgets.NotificationList { anchors.fill: parent } }
    Component { id: keybindsComponent;      Widgets.KeybindSheet { anchors.fill: parent } }
    Component { id: menuComponent;          Widgets.ContextMenu { anchors.fill: parent } }
    Component { id: themeComponent;         Widgets.ThemePanel { anchors.fill: parent } }

    // Model for the collapsed strip icons: click opens the matching context.
    // Section data (glyph/key/label) is shared with the menu and PanelKeys.
    readonly property var collapsedIconModel: PanelKeys.sections.map(section => ({
        glyph: section.glyph,
        active: PanelState.rightPanelContext === section.context,
        target: section.context
    }))
}
