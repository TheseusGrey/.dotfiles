pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Which panel is currently active (empty = none)
    // Values: "left", "right", ""
    property string activePanel: ""

    // What content the right panel should show when open
    // Values: "volume", "brightness", "wifi", "bluetooth", "power", "notifications", "keybinds", ""
    property string rightPanelContext: ""

    // Requested finder mode (set before opening finder, consumed by Finder on visible)
    // Values: "apps", "screenshot", "keybinds", "" (empty = default/apps)
    property string finderRequestedMode: ""

    // Whether the floating Finder popup is visible
    property bool finderVisible: false

    // Whether left panel is expanded
    property bool leftExpanded: false

    // ─── OSD signals ─────────────────────────────────────────────────
    // These are emitted by IPC and consumed by OsdOverlay via Connections
    signal osdRequested(type: string, value: real, muted: bool)

    // Lock screen signal
    signal lockRequested()

    function showOsd(type: string, value: real, muted: bool) {
        osdRequested(type, value, muted || false);
    }

    function requestLock() {
        lockRequested();
    }

    function toggleLeft() {
        if (leftExpanded) {
            leftExpanded = false;
            if (activePanel === "left") activePanel = "";
        } else {
            leftExpanded = true;
            activePanel = "left";
            // Close right if open
            rightPanelContext = "";
            // Close finder if open
            finderVisible = false;
        }
    }

    function openRight(context: string) {
        if (activePanel === "right" && rightPanelContext === context) {
            // Toggle off if same context clicked again
            closeRight();
        } else {
            rightPanelContext = context;
            activePanel = "right";
            // Collapse left if expanded
            leftExpanded = false;
            // Close finder if open
            finderVisible = false;
        }
    }

    function closeRight() {
        rightPanelContext = "";
        if (activePanel === "right") activePanel = "";
    }

    function toggleFinder() {
        if (finderVisible) {
            closeFinder();
        } else {
            finderVisible = true;
            // Close other panels
            rightPanelContext = "";
            leftExpanded = false;
            activePanel = "";
        }
    }

    function openFinder(mode: string) {
        finderRequestedMode = mode;
        finderVisible = true;
        // Close other panels
        rightPanelContext = "";
        leftExpanded = false;
        activePanel = "";
    }

    function closeFinder() {
        finderVisible = false;
    }

    function closeAll() {
        activePanel = "";
        rightPanelContext = "";
        leftExpanded = false;
        finderVisible = false;
    }
}
