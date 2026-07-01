import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// Finder — fzf-style app launcher.
// Immediate keyboard focus, fuzzy text filtering, arrow keys to navigate.
// Visual style: text input with │ cursor, filtered list below.
// Enter to launch, Escape to close.
//
// Flow:
// 1. Panel opens → TextInput gets focus
// 2. Type to filter (fuzzy match on app name)
// 3. Arrow keys move selection highlight (bold + accent)
// 4. Enter launches selected app
// 5. Escape closes panel
Item {
    id: root

    // ─── App data ────────────────────────────────────────────────────
    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: 0
    property string query: ""
    property bool appsLoaded: false  // cache flag — only reload on timer

    // ─── App loading (cached — loads once, refreshes every 60s) ──────
    Process {
        id: appLoader
        command: ["sh", "-c", "~/.config/quickshell/scripts/list-apps.sh"]
        running: false

        property var pendingApps: []

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line === "") return;
                try {
                    const app = JSON.parse(line);
                    if (app.name && app.exec) {
                        appLoader.pendingApps.push(app);
                    }
                } catch (e) {
                    // Skip malformed lines
                }
            }
        }

        onRunningChanged: {
            if (!running && pendingApps.length > 0) {
                // Commit loaded apps atomically
                root.allApps = pendingApps;
                root.appsLoaded = true;
                root.updateFilter();
            }
        }
    }

    // Refresh app list every 60s (apps rarely change mid-session)
    Timer {
        id: refreshAppsTimer
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            appLoader.pendingApps = [];
            appLoader.running = true;
        }
    }

    // Initial load on first creation
    Component.onCompleted: {
        appLoader.pendingApps = [];
        appLoader.running = true;
    }

    // ─── Filtering (fuzzy-ish) ───────────────────────────────────────
    function updateFilter() {
        if (root.query === "") {
            root.filteredApps = root.allApps.slice(0, 50);
        } else {
            const q = root.query.toLowerCase();
            let scored = [];
            for (let i = 0; i < root.allApps.length; i++) {
                const app = root.allApps[i];
                const name = app.name.toLowerCase();
                const score = fuzzyScore(q, name);
                if (score > 0) {
                    scored.push({ app: app, score: score });
                }
            }
            scored.sort((a, b) => b.score - a.score);
            root.filteredApps = scored.slice(0, 50).map(s => s.app);
        }
        root.selectedIndex = 0;
    }

    // Simple fuzzy scoring: sequential character matching with bonus for
    // consecutive matches and start-of-word matches.
    function fuzzyScore(query, target) {
        let qi = 0;
        let score = 0;
        let consecutive = 0;
        let lastMatchIdx = -2;

        for (let ti = 0; ti < target.length && qi < query.length; ti++) {
            if (target[ti] === query[qi]) {
                qi++;
                score += 1;

                // Bonus for consecutive characters
                if (ti === lastMatchIdx + 1) {
                    consecutive++;
                    score += consecutive * 2;
                } else {
                    consecutive = 0;
                }

                // Bonus for start of word
                if (ti === 0 || target[ti - 1] === ' ' || target[ti - 1] === '-' || target[ti - 1] === '_') {
                    score += 5;
                }

                lastMatchIdx = ti;
            }
        }

        // All query chars must be matched
        return qi === query.length ? score : 0;
    }

    // ─── App launching ───────────────────────────────────────────────
    Process {
        id: launchProc
        running: false
    }

    function launchApp(app) {
        launchProc.command = ["sh", "-c", app.exec + " &"];
        launchProc.running = true;
        PanelState.closeAll();
    }

    function launchSelected() {
        if (root.filteredApps.length > 0 && root.selectedIndex < root.filteredApps.length) {
            launchApp(root.filteredApps[root.selectedIndex]);
        }
    }

    // ─── Keyboard handling ───────────────────────────────────────────
    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            root.query = "";
            root.selectedIndex = 0;
            root.updateFilter();
            searchInput.forceActiveFocus();
        }
    }

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.itemSpacing

        // ─── Search input ────────────────────────────────────────────
        // Styled like a TUI text input: > prompt, blinking cursor
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: searchRow.implicitHeight + 8

            Rectangle {
                anchors.fill: parent
                color: Theme.bgElevated
            }

            RowLayout {
                id: searchRow
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6

                // Prompt character
                Tui.TuiText {
                    text: ">"
                    textColor: Theme.accent
                    font.bold: true
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    selectByMouse: true
                    selectionColor: Theme.bgHover
                    selectedTextColor: Theme.textBright
                    clip: true

                    onTextChanged: {
                        root.query = text;
                        root.updateFilter();
                    }

                    Keys.onUpPressed: {
                        if (root.selectedIndex > 0) root.selectedIndex--;
                    }
                    Keys.onDownPressed: {
                        if (root.selectedIndex < root.filteredApps.length - 1) root.selectedIndex++;
                    }
                    Keys.onReturnPressed: root.launchSelected()
                    Keys.onEnterPressed: root.launchSelected()
                    Keys.onEscapePressed: PanelState.closeAll()
                }
            }
        }

        // ─── Match count ─────────────────────────────────────────────
        Tui.TuiText {
            text: root.filteredApps.length + "/" + root.allApps.length
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }

        // ─── Results list ────────────────────────────────────────────
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: resultColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: resultColumn
                width: parent.width
                spacing: 0

                Repeater {
                    model: root.filteredApps

                    Item {
                        id: appItem
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: appRow.implicitHeight + 6

                        readonly property bool isSelected: index === root.selectedIndex

                        // Selection background — gradient for selected, flat for hover
                        Rectangle {
                            anchors.fill: parent
                            visible: appItem.isSelected
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.bgHover }
                                GradientStop { position: 0.7; color: Theme.bgElevated }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: !appItem.isSelected && appItemMouse.containsMouse
                            color: Theme.bgElevated
                        }

                        RowLayout {
                            id: appRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 8

                            // Selection indicator
                            Tui.TuiText {
                                text: appItem.isSelected ? ">" : " "
                                textColor: Theme.accent
                                font.bold: true
                            }

                            // App name
                            Tui.TuiText {
                                text: appItem.modelData.name
                                textColor: appItem.isSelected ? Theme.accent : Theme.textPrimary
                                font.bold: appItem.isSelected
                                Layout.fillWidth: true

                                // Truncate long names
                                elide: Text.ElideRight
                            }

                            // Comment/description (dim, italic, truncated)
                            Tui.TuiText {
                                visible: appItem.modelData.comment !== undefined && appItem.modelData.comment !== ""
                                text: {
                                    const c = appItem.modelData.comment || "";
                                    return c.length > 25 ? c.substring(0, 25) + "…" : c;
                                }
                                textColor: Theme.textMuted
                                font.pixelSize: Theme.fontSizeSmall
                                font.italic: true
                            }
                        }

                        MouseArea {
                            id: appItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = appItem.index;
                                root.launchSelected();
                            }
                        }
                    }
                }
            }
        }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: "↑↓:navigate  enter:launch  esc:close"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
