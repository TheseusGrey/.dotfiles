import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Right context panel — east edge of the TUI frame.
// Always visible as a narrow collapsed strip; expands with slide animation
// when a status icon is clicked. Content switches based on rightPanelContext.
// The panel shows an inside-the-border header text (context title) when expanded,
// mirroring the finder popup header style — no border-breaking title chip.
// Uses HyprlandFocusGrab to auto-close when clicking outside.
PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    anchors.bottom: true

    readonly property bool isExpanded: PanelState.rightPanelContext !== ""

    readonly property string contextTitle: PanelKeys.titleFor(PanelState.rightPanelContext)

    implicitWidth: isExpanded ? Theme.rightPanelExpanded : Theme.rightPanelCollapsed
    exclusiveZone: isExpanded ? Theme.rightPanelExpanded : Theme.rightPanelCollapsed
    focusable: isExpanded
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shell-right"

    // No width animation: snap open/closed (same reason as the left panel —
    // prevents the footer strip from visually "playing catch-up" at the
    // shared bottom corner mid-slide). No Behavior on implicitWidth.

    // ─── Focus grab: close on click outside ──────────────────────────
    // Keep the grab active whenever the panel is expanded (don't toggle it off
    // during theme work — releasing the grab to "protect" it fires onCleared
    // and closes the panel). Instead, suppress the close while a theme
    // operation is running (themeProcessRunning, set synchronously on click and
    // held through a short grace period). A genuine outside-click while no
    // theme op is running still closes normally.
    HyprlandFocusGrab {
        id: focusGrab
        active: root.isExpanded
        windows: [root]
        onCleared: {
            if (PanelState.themeProcessRunning) return;
            PanelState.closeRight();
        }
    }

    // ─── Keyboard navigation ──────────────────────────────────────────
    // The focus grab gives the layer surface the keyboard; this FocusScope
    // turns that into panel navigation. All panel keys are bare keys (no
    // modifier). See PanelKeys.qml for the map and the collision check.
    //
    // Focus is retried for a short window after expansion/context changes:
    // a newly mapped layer surface needs a compositor round-trip before it
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
            keyHandler.forceActiveFocus();
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

    // ─── Frame chrome (bg + blocky border) ─────────────────────────────
    // Top edge suppressed: the top bar already draws the line at the corner.
    // Right edge suppressed: display edge (open frame), bottom edge is covered
    // by the opaque footer strip anyway.
    Tui.TuiPanel {
        anchors.fill: parent
        borderTop: false
        borderRight: false
        borderBottom: false
    }

    // ─── Collapsed state: icon hint strip ────────────────────────────
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

    // ─── Expanded state: full content ────────────────────────────────
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

            // ─── Header: title + (back to menu) button ────────────────
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

            // ─── Context content ─────────────────────────────────────
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
