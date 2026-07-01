pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Which panel is currently active (empty = none)
    // Values: "left", "right", ""
    property string activePanel: ""

    // What content the right panel should show when open
    // Values: "volume", "brightness", "wifi", "bluetooth", "power", "notifications", "finder", "keybinds", ""
    property string rightPanelContext: ""

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
        }
    }

    function closeRight() {
        rightPanelContext = "";
        if (activePanel === "right") activePanel = "";
    }

    function closeAll() {
        activePanel = "";
        rightPanelContext = "";
        leftExpanded = false;
    }
}
