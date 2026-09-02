pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string qsh: "/home/ashe/.local/bin/qsh"

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

    // Whether the date hover popup is visible
    property bool datePopupVisible: false

    // Guard: while true the right panel must not auto-close (e.g. during
    // theme wallpaper/sync operations whose IPC churn can clear the focus grab).
    property bool themeProcessRunning: false

    // Whether left panel is expanded
    property bool leftExpanded: false

    // Theme switcher: whether colours are synced to the active wallpaper.
    // When true, picking a wallpaper re-derives the palette from it; when
    // false, the colour scheme is chosen from a preset instead.
    // Persisted in settings.json (key "theme.syncedToWallpaper") so it survives
    // sessions and can be shared by other tools.
    property bool themeSyncedToWallpaper: true

    // Persisted matugen material scheme type (default scheme-expressive).
    // Decoupled from themeSyncedToWallpaper; applies to image theming.
    property string themeScheme: "scheme-expressive"

    // Set the sync pref and persist it for future sessions.
    function setSyncedToWallpaper(value: bool) {
        themeSyncedToWallpaper = !!value;
        setProc.command = [root.qsh, "settings", "set", "theme.syncedToWallpaper", themeSyncedToWallpaper ? "true" : "false"];
        setProc.running = true;
    }

    // Loads the persisted value on startup (before any UX reads it).
    Component.onCompleted: {
        getProc.command = [root.qsh, "settings", "get", "theme.syncedToWallpaper"];
        getProc.running = true;
        schemeProc.command = [root.qsh, "settings", "get", "theme.scheme"];
        schemeProc.running = true;
    }

    Process {
        id: getProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = data.trim();
                // Only flip off when explicitly stored "false"; anything else
                // (missing, "true") keeps the default synced-on.
                if (v === "false") root.themeSyncedToWallpaper = false;
            }
        }
    }

    Process {
        id: schemeProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = data.trim();
                if (v) root.themeScheme = v;
            }
        }
    }

    Process {
        id: setProc
        running: false
    }

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

    // Return to the context menu list (keeps the right panel open).
    function goBackToMenu() {
        if (activePanel !== "right") {
            activePanel = "right";
            leftExpanded = false;
        }
        rightPanelContext = "menu";
    }

    // True while the right panel is showing an actual sub-content (not the
    // menu list itself), so the header can offer a back button.
    readonly property bool rightPanelCanGoBack: activePanel === "right" && rightPanelContext !== "" && rightPanelContext !== "menu"

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
        datePopupVisible = false;
    }

    function closeDatePopup() {
        datePopupVisible = false;
    }
}
