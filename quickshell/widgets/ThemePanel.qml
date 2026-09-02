import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components as Tui

// Theme switcher panel — lets the user pick a wallpaper (with preview and the
// palette it would derive) and choose between syncing colours to the current
// wallpaper or applying a fixed colour-scheme preset.
//
// Wallpapers and presets are enumerated at open time via `qsh`; applying runs
// `qsh wallpaper <name>` / `qsh theme <name>` (which regenerate the live
// Colors.qml / hypr / waybar files). The panel stays open so the user sees the
// result; the theme hot-reloads through the existing shell wiring.
Item {
    id: root

    readonly property string qsh: "/home/ashe/.local/bin/qsh"
    readonly property var imageExts: [".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"]

    // Image-extension filter so a bad enumeration line can never leak into the
    // wallpaper grid as an empty card.
    function isImage(name) {
        const low = name.toLowerCase();
        for (const ext of root.imageExts) {
            if (low.endsWith(ext)) return true;
        }
        return false;
    }

    // ─── Models (populated async) ──────────────────────────────────
    property var wallpapers: []
    property var presets: []

    // Matugen material scheme types offered in the scheme dropdown.
    readonly property var schemes: [
        { label: "expressive", value: "scheme-expressive" },
        { label: "fidelity",   value: "scheme-fidelity" },
        { label: "vibrant",    value: "scheme-vibrant" },
        { label: "content",    value: "scheme-content" },
        { label: "fruit salad",value: "scheme-fruit-salad" },
        { label: "rainbow",    value: "scheme-rainbow" },
        { label: "neutral",    value: "scheme-neutral" },
        { label: "monochrome", value: "scheme-monochrome" },
        { label: "tonal spot", value: "scheme-tonal-spot" },
        { label: "smart",      value: "scheme-smart" }
    ]

    // dropdown + apply state
    property bool presetsOpen: false
    property bool schemesOpen: false
    property bool applying: false

    // Human label for the currently persisted scheme type (default expressive).
    readonly property string currentSchemeLabel: {
        const known = root.schemes.filter(s => PanelState.themeScheme === s.value);
        return known.length > 0 ? known[0].label : "expressive";
    }

    // Every theme colour, for the palette swatch grid.
    readonly property var paletteColours: [
        { label: "bg",      color: Colors.bg },
        { label: "elev",    color: Colors.bgElevated },
        { label: "hover",   color: Colors.bgHover },
        { label: "border",  color: Colors.border },
        { label: "faint",   color: Colors.borderFaint },
        { label: "text",    color: Colors.textPrimary },
        { label: "bright",  color: Colors.textBright },
        { label: "muted",   color: Colors.textMuted },
        { label: "accentFg", color: Colors.accentFg },
        { label: "accent",  color: Colors.accent },
        { label: "accent2", color: Colors.accentSecondary },
        { label: "utility", color: Colors.utility },
        { label: "info",    color: Colors.info },
        { label: "error",   color: Colors.error },
        { label: "warning", color: Colors.warning },
        { label: "success", color: Colors.success },
        { label: "caution", color: Colors.caution }
    ]

    readonly property string wallpaperDir: "/home/ashe/.dotfiles/wallpapers"

    // Re-enumerate the wallpaper folder. Only updates the model when the actual
    // list changes, so a filewatch-triggered refresh never causes the grid to
    // jump/flash.
    function refreshWallpapers() {
        if (wallProc.running) return;
        wallProc.buffer = "";
        wallProc.command = [root.qsh, "wallpapers"];
        wallProc.running = true;
    }

    // ─── Wallpaper list enumeration ────────────────────────────────
    Process {
        id: wallProc
        property string buffer: ""
        running: false

        stdout: SplitParser {
            onRead: data => { wallProc.buffer += data + "\n"; }
        }
        onRunningChanged: {
            if (!running && wallProc.buffer !== undefined) {
                const lines = wallProc.buffer.trim().split("\n");
                let arr = [];
                for (const l of lines) {
                    const name = l.trim();
                    if (name !== "" && root.isImage(name)) arr.push(name);
                }
                if (arr.join("\u0001") !== root.wallpapers.join("\u0001")) {
                    root.wallpapers = arr;
                }
            }
        }
    }

    Process {
        id: presetProc
        property string buffer: ""
        running: false

        stdout: SplitParser {
            onRead: data => { presetProc.buffer += data + "\n"; }
        }
        onRunningChanged: {
            if (!running && presetProc.buffer !== undefined) {
                const lines = presetProc.buffer.trim().split("\n");
                let arr = [];
                for (const l of lines) {
                    if (l.trim() !== "") arr.push(l.trim());
                }
                root.presets = arr;
            }
        }
    }

    // ─── Apply commands ─────────────────────────────────────────────
    Process {
        id: applyProc
        property string buffer: ""
        running: false
        onRunningChanged: {
            if (running) {
                PanelState.themeProcessRunning = true;
            } else {
                root.rearmTimer.restart();
            }
        }
    }

    Process {
        id: syncProc
        running: false
        onRunningChanged: {
            if (running) {
                PanelState.themeProcessRunning = true;
            } else {
                root.rearmTimer.restart();
            }
        }
    }

    // Because matugen/hyprpaper churn can clear the focus grab a moment AFTER
    // the process returns (hyprctl reload etc), keep the grab disabled for a
    // short grace period after the work finishes — otherwise the panel
    // collapses mid-action.
    Timer {
        id: rearmTimer
        interval: 800
        onTriggered: {
            PanelState.themeProcessRunning = false;
        }
    }

    // Set the guard synchronously on click (before the compositor reacts to the
    // click as an outside-focus event) so the panel can't close from the very
    // action that started the work.
    function beginThemeAction() {
        PanelState.themeProcessRunning = true;
        rearmTimer.stop();
    }

    function applyWallpaper(name) {
        root.beginThemeAction();
        applyProc.command = [root.qsh, "wallpaper", name];
        applyProc.running = true;
    }

    function applyPreset(name) {
        root.presetsOpen = false;
        root.beginThemeAction();
        applyProc.command = [root.qsh, "theme", name];
        applyProc.running = true;
    }

    function toggleSync(on) {
        PanelState.setSyncedToWallpaper(on);
        root.beginThemeAction();
        syncProc.command = [root.qsh, "sync", on ? "on" : "off"];
        syncProc.running = true;
    }

    // Persist the chosen matugen scheme and regenerate from the current
    // wallpaper so the new colour generation is applied immediately.
    function applyScheme(value) {
        root.schemesOpen = false;
        PanelState.themeScheme = value;
        root.beginThemeAction();
        applyProc.command = [root.qsh, "scheme", value];
        applyProc.running = true;
    }

    Component.onCompleted: {
        root.refreshWallpapers();
        presetProc.command = [root.qsh, "themes"];
        presetProc.running = true;
    }

    // ─── Filewatch ─────────────────────────────────────────────────
    // No native QFileSystemWatcher is exposed via Quickshell.Io, so we poll
    // while the panel is visible. The model only updates on an actual change,
    // so adding/removing files in the folder refreshes the grid automatically.
    Timer {
        id: wallWatch
        interval: 3000
        repeat: true
        running: root.visible
        onTriggered: root.refreshWallpapers()
    }

    onVisibleChanged: {
        if (root.visible) {
            root.refreshWallpapers();
            wallWatch.restart();
        }
    }

    // ─── Open wallpaper folder in the default file manager ────────
    Process {
        id: openDirProc
    }

    function openFolder() {
        openDirProc.command = ["sh", "-c", "xdg-open " + root.wallpaperDir];
        openDirProc.startDetached();
        // Close the panel so the file manager isn't competing for the screen.
        PanelState.closeRight();
    }

    // ─── Layout ─────────────────────────────────────────────────────
    Flickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: parent.width
            spacing: Theme.itemSpacing

            // ─── Sync toggle ────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.itemSpacing

                Tui.TuiButton {
                    id: syncToggle
                    text: PanelState.themeSyncedToWallpaper ? "[x]" : "[ ]"
                    variant: "body"
                    active: PanelState.themeSyncedToWallpaper
                    onClicked: {
                        root.toggleSync(!PanelState.themeSyncedToWallpaper);
                    }
                }

                Tui.TuiText {
                    text: "sync colours to wallpaper"
                    textColor: Theme.textPrimary
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                }
            }

            // ─── Scheme dropdown (image theming) ────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: PanelState.themeSyncedToWallpaper
                opacity: PanelState.themeSyncedToWallpaper ? 1.0 : 0.5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.itemSpacing

                    Tui.TuiButton {
                        text: root.schemesOpen ? "▼" : "▸"
                        variant: "body"
                        active: root.schemesOpen
                        disabled: !PanelState.themeSyncedToWallpaper
                        onClicked: root.schemesOpen = !root.schemesOpen
                    }

                    Tui.TuiText {
                        text: "generation " + root.currentSchemeLabel
                        textColor: Theme.textMuted
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }
                }

                Flickable {
                    id: schemeList
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.schemesOpen ? Math.min(schemeList.contentHeight, 260) : 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: schemeCol.implicitHeight
                    visible: root.schemesOpen

                    Column {
                        id: schemeCol
                        width: schemeList.width
                        spacing: 0

                        Repeater {
                            model: root.schemes

                            Tui.TuiMenuItem {
                                required property var modelData
                                text: modelData.label
                                marker: ">"
                                selected: root.currentSchemeLabel === modelData.label
                                width: schemeCol.width
                                onClicked: root.applyScheme(modelData.value)
                            }
                        }
                    }
                }

                Tui.TuiText {
                    visible: !root.schemesOpen
                    text: "open list to choose a scheme"
                    textColor: Theme.borderFaint
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            // ─── Preset dropdown ────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: !PanelState.themeSyncedToWallpaper
                opacity: PanelState.themeSyncedToWallpaper ? 0.5 : 1.0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.itemSpacing

                    Tui.TuiButton {
                        text: root.presetsOpen ? "▼" : "▸"
                        variant: "body"
                        active: root.presetsOpen
                        disabled: PanelState.themeSyncedToWallpaper
                        onClicked: root.presetsOpen = !root.presetsOpen
                    }

                    Tui.TuiText {
                        text: "colour scheme"
                        textColor: Theme.textMuted
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }
                }

                Flickable {
                    id: presetList
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.presetsOpen ? Math.min(presetList.contentHeight, 200) : 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: presetCol.implicitHeight
                    visible: root.presetsOpen

                    Column {
                        id: presetCol
                        width: presetList.width
                        spacing: 0

                        Repeater {
                            model: root.presets

                            Tui.TuiMenuItem {
                                required property string modelData
                                text: modelData
                                marker: ">"
                                width: presetCol.width
                                onClicked: root.applyPreset(modelData)
                            }
                        }
                    }
                }

                Tui.TuiText {
                    visible: !root.presetsOpen
                    text: "open list to pick a scheme"
                    textColor: Theme.borderFaint
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            // ─── Current palette ─────────────────────────────────────
            Tui.TuiRule {
                Layout.fillWidth: true
                Layout.topMargin: 4
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: Theme.itemSpacing

                Tui.TuiText {
                    text: "palette"
                    textColor: Theme.textMuted
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                }
            }

            // block swatches of every theme colour (fixed-size squares, tiny
            // gap, radius 0 — matches the blocky tile aesthetic). Flow wraps
            // to further rows so the row never overflows the panel width.
            Flow {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.paletteColours

                    Rectangle {
                        required property var modelData
                        width: Tui.TuiMetrics.cellWidth * 3
                        height: Tui.TuiMetrics.cellWidth * 3
                        radius: 0
                        border.width: 1
                        border.color: Colors.borderFaint
                        color: modelData.color
                    }
                }
            }

            // ─── Divider ────────────────────────────────────────────
            Tui.TuiRule {
                Layout.fillWidth: true
                Layout.topMargin: 4
            }

            // ─── Wallpaper picker ───────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.itemSpacing
                Layout.bottomMargin: 2

                Tui.TuiText {
                    text: "background"
                    textColor: Theme.textMuted
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                }

                Tui.TuiButton {
                    text: "open folder"
                    variant: "body"
                    onClicked: root.openFolder()
                }
            }

            GridLayout {
                id: wallGrid
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Theme.itemSpacing
                rowSpacing: Theme.itemSpacing

                Repeater {
                    model: root.wallpapers

                    WallpaperThumb {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: wallGrid.width / 2 - Theme.itemSpacing / 2
                        fileName: modelData
                        onApplied: root.applyWallpaper(modelData)
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
