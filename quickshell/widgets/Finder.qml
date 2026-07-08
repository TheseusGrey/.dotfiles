import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components as Tui

// Finder — multi-mode fuzzy search launcher.
//
// Modes (Tab to cycle):
//   apps       — desktop applications (default)
//   screenshot — capture.sh screen actions
//   keybinds   — searchable Hyprland keybinds
//
// Features:
//   - fzf-equivalent fuzzy scoring (sequential match, word boundary bonus,
//     consecutive bonus, camelCase bonus)
//   - Character-level match highlighting via RichText <span> tags
//   - Arrow keys navigate, Enter activates, Escape closes
//   - Mode indicator in prompt area
//
Item {
    id: root

    // ─── Mode system ─────────────────────────────────────────────────
    // "custom" mode is NOT in the cycle list — it's only activated via FinderServer
    readonly property var modes: ["apps", "screenshot", "keybinds"]
    property int currentModeIndex: 0
    property string currentMode: modes[currentModeIndex]

    // External mode override (set by openFinder IPC via PanelState.finderRequestedMode)

    function cycleMode() {
        // Cannot cycle away from custom mode — Escape to cancel
        if (currentMode === "custom") return;
        currentModeIndex = (currentModeIndex + 1) % modes.length;
        currentMode = modes[currentModeIndex];
        query = "";
        searchInput.text = "";
        selectedIndex = 0;
        updateFilter();
    }

    // Set a specific mode by name (used by IPC openFinder)
    function setMode(mode) {
        if (mode === "custom") {
            // Custom mode is handled specially
            root.currentMode = "custom";
            return;
        }
        const idx = modes.indexOf(mode);
        if (idx !== -1) {
            currentModeIndex = idx;
            root.currentMode = modes[idx];
        }
    }

    // ─── Common state ────────────────────────────────────────────────
    property var filteredItems: []   // [{name, subtitle, data, matchIndices}]
    property int selectedIndex: 0
    property string query: ""

    // ─── Apps data (native DesktopEntries API) ─────────────────────
    // Uses Quickshell's built-in DesktopEntries singleton which properly
    // scans all XDG directories, handles OnlyShowIn/NotShowIn, NoDisplay,
    // localization, and desktop actions per the freedesktop spec.
    readonly property bool appsLoaded: DesktopEntries.applications.values.length > 0

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            if (root.currentMode === "apps") root.updateFilter();
        }
    }

    // ─── Screenshot data ─────────────────────────────────────────────
    readonly property var screenshotActions: [
        { name: "Screenshot Region",  icon: "", cmd: "hyprshot -m region" },
        { name: "Screenshot Screen",  icon: "", cmd: "hyprshot -m output" },
        { name: "Screenshot Window",  icon: "", cmd: "hyprshot -m window" },
        { name: "Color Picker",       icon: "󰃉", cmd: "hyprpicker | wl-copy -n" },
        { name: "Screen Record",      icon: "", cmd: "notify-send 'Not implemented'" }
    ]

    // ─── Keybinds data ───────────────────────────────────────────────
    property var allKeybinds: []
    property bool keybindsLoaded: false

    Process {
        id: keybindLoader
        command: ["hyprctl", "-j", "binds"]
        running: false

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => { keybindLoader.buffer += data + "\n"; }
        }

        onRunningChanged: {
            if (!running) {
                try {
                    const parsed = JSON.parse(keybindLoader.buffer);
                    let result = [];
                    for (let i = 0; i < parsed.length; i++) {
                        const b = parsed[i];
                        const mods = root.modMaskToString(b.modmask || 0);
                        const key = b.key || "";
                        const combo = mods ? mods + " + " + key : key;
                        const desc = b.description || root.dispatcherDescription(b.dispatcher, b.arg);
                        result.push({
                            name: combo,
                            subtitle: desc,
                            dispatcher: b.dispatcher,
                            arg: b.arg
                        });
                    }
                    root.allKeybinds = result;
                    root.keybindsLoaded = true;
                } catch (e) {
                    root.allKeybinds = [];
                }
                keybindLoader.buffer = "";
                if (root.currentMode === "keybinds") root.updateFilter();
            }
        }
    }

    function modMaskToString(mask) {
        let parts = [];
        if (mask & 64) parts.push("super");
        if (mask & 1) parts.push("shift");
        if (mask & 4) parts.push("ctrl");
        if (mask & 8) parts.push("alt");
        return parts.join("+");
    }

    function dispatcherDescription(dispatcher, arg) {
        switch (dispatcher) {
            case "exec": return arg ? arg.split("/").pop().split(" ")[0] : "run command";
            case "killactive": return "close window";
            case "movefocus": return "focus " + arg;
            case "workspace": return "workspace " + arg;
            case "movetoworkspace": return "move to ws " + arg;
            case "movewindow": return "move window " + arg;
            case "resizeactive": return "resize window";
            case "togglefloating": return "toggle float";
            case "fullscreen": return "fullscreen";
            case "togglesplit": return "toggle split";
            case "movewindow": return "move window " + arg;
            default: return dispatcher + (arg ? " " + arg : "");
        }
    }

    // ─── Initialization ──────────────────────────────────────────────
    Component.onCompleted: {
        keybindLoader.running = true;
    }

    // ─── FinderServer integration (custom mode) ──────────────────────
    Connections {
        target: FinderServer
        function onCustomRequestReceived() {
            // Switch to custom mode when a socket request arrives
            root.currentMode = "custom";
            root.query = "";
            root.selectedIndex = 0;
            if (root.visible) {
                searchInput.text = "";
                root.updateFilter();
                searchInput.forceActiveFocus();
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            root.query = "";
            root.selectedIndex = 0;
            // If there's a pending custom request, stay in custom mode
            if (FinderServer.hasPendingRequest) {
                root.currentMode = "custom";
            } else if (PanelState.finderRequestedMode !== "") {
                root.setMode(PanelState.finderRequestedMode);
                PanelState.finderRequestedMode = "";
            } else {
                root.currentModeIndex = 0;
                root.currentMode = modes[0];
            }
            root.updateFilter();
            searchInput.forceActiveFocus();
        } else {
            // Panel closed — if custom mode was active, cancel the request
            if (root.currentMode === "custom" && FinderServer.hasPendingRequest) {
                FinderServer.resolveCancelled();
            }
        }
    }

    // ─── fzf-equivalent fuzzy matching ───────────────────────────────
    // Returns { score: number, indices: number[] } or null if no match.
    //
    // Scoring rules (modeled after fzf's algorithm):
    //   +1 per matched char
    //   +5 bonus for word boundary match (after space, -, _, /)
    //   +3 bonus for camelCase boundary (lowercase→uppercase)
    //   +consecutive*2 bonus for consecutive matched chars
    //   +10 bonus for first char match (prefix match)
    //   -1 penalty per gap between matches (max -3 per gap)
    //
    function fuzzyMatch(query, target) {
        if (query === "") return { score: 0, indices: [] };

        const q = query.toLowerCase();
        const t = target.toLowerCase();
        const tOrig = target;
        const qLen = q.length;
        const tLen = t.length;

        // Quick reject: query longer than target
        if (qLen > tLen) return null;

        // Quick check: all chars exist in target
        let checkIdx = 0;
        for (let i = 0; i < qLen; i++) {
            checkIdx = t.indexOf(q[i], checkIdx);
            if (checkIdx === -1) return null;
            checkIdx++;
        }

        // Full scoring pass with backtracking for optimal match
        const result = root.fuzzyMatchRecursive(q, t, tOrig, 0, 0, [], 0);
        return result;
    }

    function fuzzyMatchRecursive(query, targetLower, targetOrig, qi, ti, indices, depth) {
        if (depth > 10) return null;  // recursion limit
        if (qi === query.length) {
            // Score the match
            return { score: root.scoreMatch(indices, targetLower, targetOrig), indices: indices };
        }
        if (ti >= targetLower.length) return null;

        let bestResult = null;

        for (let i = ti; i < targetLower.length; i++) {
            if (targetLower[i] === query[qi]) {
                // Try matching here
                const newIndices = indices.concat([i]);
                const result = root.fuzzyMatchRecursive(query, targetLower, targetOrig, qi + 1, i + 1, newIndices, depth + 1);
                if (result && (!bestResult || result.score > bestResult.score)) {
                    bestResult = result;
                }
                // Only try the first few alternatives to keep performance sane
                if (depth > 3) break;
            }
        }
        return bestResult;
    }

    function scoreMatch(indices, targetLower, targetOrig) {
        let score = 0;
        let consecutive = 0;

        for (let i = 0; i < indices.length; i++) {
            const idx = indices[i];
            score += 1;  // base point per match

            // First char bonus
            if (idx === 0) score += 10;

            // Consecutive bonus
            if (i > 0 && idx === indices[i - 1] + 1) {
                consecutive++;
                score += consecutive * 2;
            } else {
                // Gap penalty (mild)
                if (i > 0) {
                    const gap = idx - indices[i - 1] - 1;
                    score -= Math.min(gap, 3);
                }
                consecutive = 0;
            }

            // Word boundary bonus
            if (idx === 0 || " -_/".indexOf(targetLower[idx - 1]) !== -1) {
                score += 5;
            }

            // CamelCase bonus
            if (idx > 0 && targetOrig[idx - 1] === targetOrig[idx - 1].toLowerCase()
                && targetOrig[idx] === targetOrig[idx].toUpperCase()
                && targetOrig[idx] !== targetOrig[idx].toLowerCase()) {
                score += 3;
            }
        }

        // Length penalty: prefer shorter targets (less noise)
        score -= Math.floor(targetLower.length / 10);

        return score;
    }

    // ─── Highlight rendering ─────────────────────────────────────────
    // Takes a string and array of matched indices, returns RichText HTML
    // with matched chars in accent color.
    function highlightMatch(text, indices) {
        if (!indices || indices.length === 0) {
            return escapeHtml(text);
        }

        const indexSet = {};
        for (let i = 0; i < indices.length; i++) {
            indexSet[indices[i]] = true;
        }

        let result = "";
        let inHighlight = false;

        for (let i = 0; i < text.length; i++) {
            const isMatch = indexSet[i] === true;
            if (isMatch && !inHighlight) {
                result += '<span style="color:' + Theme.nord13 + ';font-weight:bold">';
                inHighlight = true;
            } else if (!isMatch && inHighlight) {
                result += '</span>';
                inHighlight = false;
            }
            result += escapeHtml(text[i]);
        }
        if (inHighlight) result += '</span>';
        return result;
    }

    function escapeHtml(str) {
        return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // ─── Filtering (all modes) ───────────────────────────────────────
    function updateFilter() {
        const items = getSourceItems();
        if (root.query === "") {
            // No query — show all items without highlighting
            let result = [];
            const limit = Math.min(items.length, 50);
            for (let i = 0; i < limit; i++) {
                result.push({
                    name: items[i].name,
                    subtitle: items[i].subtitle || "",
                    data: items[i],
                    matchIndices: [],
                    nameHtml: escapeHtml(items[i].name)
                });
            }
            root.filteredItems = result;
        } else {
            let scored = [];
            for (let i = 0; i < items.length; i++) {
                const item = items[i];
                // Match against name primarily
                const nameResult = fuzzyMatch(root.query, item.name);
                // Also try matching against subtitle for better recall
                const subResult = item.subtitle ? fuzzyMatch(root.query, item.subtitle) : null;
                // Also try keywords (semicolon-separated, treated as space-separated terms)
                const kwResult = item.keywords ? fuzzyMatch(root.query, item.keywords.replace(/;/g, " ")) : null;

                let bestScore = 0;
                let bestIndices = [];
                let matchedField = "name";

                if (nameResult) {
                    bestScore = nameResult.score;
                    bestIndices = nameResult.indices;
                }
                if (subResult && subResult.score > bestScore) {
                    bestScore = subResult.score;
                    bestIndices = subResult.indices;
                    matchedField = "subtitle";
                }
                if (kwResult && kwResult.score > bestScore) {
                    // Keywords matched — show as name match (no highlight on keywords)
                    bestScore = kwResult.score;
                    bestIndices = [];
                    matchedField = "name";
                }

                if (bestScore > 0) {
                    scored.push({
                        name: item.name,
                        subtitle: item.subtitle || "",
                        data: item,
                        score: bestScore,
                        matchIndices: matchedField === "name" ? bestIndices : [],
                        subtitleIndices: matchedField === "subtitle" ? bestIndices : [],
                        nameHtml: matchedField === "name"
                            ? highlightMatch(item.name, bestIndices)
                            : escapeHtml(item.name),
                        subtitleHtml: matchedField === "subtitle"
                            ? highlightMatch(item.subtitle, bestIndices)
                            : undefined
                    });
                }
            }
            scored.sort((a, b) => b.score - a.score);
            root.filteredItems = scored.slice(0, 50);
        }
        root.selectedIndex = 0;
    }

    function getSourceItems() {
        switch (root.currentMode) {
            case "apps":
                const entries = DesktopEntries.applications.values;
                let apps = [];
                for (let i = 0; i < entries.length; i++) {
                    const e = entries[i];
                    apps.push({
                        name: e.name,
                        subtitle: e.comment || e.genericName || "",
                        keywords: (e.keywords || []).join(";"),
                        entry: e,
                        type: "app"
                    });
                    // Include desktop actions as separate entries
                    if (e.actions && e.actions.length > 0) {
                        for (let j = 0; j < e.actions.length; j++) {
                            const action = e.actions[j];
                            apps.push({
                                name: e.name + " — " + action.name,
                                subtitle: "",
                                keywords: "",
                                entry: e,
                                action: action,
                                type: "app"
                            });
                        }
                    }
                }
                return apps;
            case "screenshot":
                return root.screenshotActions.map(a => ({
                    name: a.name,
                    subtitle: a.icon,
                    cmd: a.cmd,
                    type: "screenshot"
                }));
            case "keybinds":
                return root.allKeybinds.map(k => ({
                    name: k.name,
                    subtitle: k.subtitle,
                    dispatcher: k.dispatcher,
                    arg: k.arg,
                    type: "keybind"
                }));
            case "custom":
                return FinderServer.customItems.map(item => ({
                    name: item,
                    subtitle: "",
                    type: "custom"
                }));
            default:
                return [];
        }
    }

    // ─── Activation ──────────────────────────────────────────────────
    Process {
        id: launchProc
        running: false
    }

    function activateItem(item) {
        const data = item.data;
        switch (data.type) {
            case "app":
                if (data.action) {
                    // Desktop action — execute action's command
                    data.action.execute();
                } else {
                    // Main entry — use native execute()
                    data.entry.execute();
                }
                PanelState.closeAll();
                break;
            case "screenshot":
                launchProc.command = ["sh", "-c", data.cmd + " &"];
                launchProc.running = true;
                PanelState.closeAll();
                break;
            case "keybind":
                // For keybinds, just close — it's informational
                // (user is searching to remember what a key does)
                PanelState.closeAll();
                break;
            case "custom":
                // Send selection back to the socket client
                FinderServer.resolveSelection(data.name);
                PanelState.closeAll();
                break;
        }
    }

    function activateSelected() {
        if (root.filteredItems.length > 0 && root.selectedIndex < root.filteredItems.length) {
            activateItem(root.filteredItems[root.selectedIndex]);
        }
    }

    // ─── Layout ──────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.itemSpacing

        // ─── Mode indicator (Tab to switch) ──────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            // Custom mode indicator (replaces normal mode tabs)
            Tui.TuiText {
                visible: root.currentMode === "custom"
                text: "[" + (FinderServer.customPrompt || "select") + "]"
                textColor: Theme.nord15
                font.bold: true
                font.pixelSize: Theme.fontSizeSmall
            }

            // Normal mode tabs (hidden during custom mode)
            Repeater {
                model: root.currentMode !== "custom" ? root.modes : []

                Tui.TuiText {
                    required property var modelData
                    required property int index
                    text: {
                        const label = modelData;
                        return index === root.currentModeIndex
                            ? "[" + label + "]"
                            : " " + label + " ";
                    }
                    textColor: {
                        if (index !== root.currentModeIndex) return Theme.textMuted;
                        // Each mode gets its own color
                        switch (modelData) {
                            case "apps": return Theme.nord14;       // green
                            case "screenshot": return Theme.nord12; // orange
                            case "keybinds": return Theme.nord13;   // yellow
                            default: return Theme.accent;
                        }
                    }
                    font.bold: index === root.currentModeIndex
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            Item { Layout.fillWidth: true }

            Tui.TuiText {
                visible: root.currentMode !== "custom"
                text: "tab:mode"
                textColor: Theme.nord7  // teal hint
                font.pixelSize: Theme.fontSizeSmall
            }

            Tui.TuiText {
                visible: root.currentMode === "custom"
                text: "esc:cancel"
                textColor: Theme.nord11  // red for cancel hint
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        // ─── Search input ────────────────────────────────────────────
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
                    textColor: {
                        switch (root.currentMode) {
                            case "apps": return Theme.nord14;       // green
                            case "screenshot": return Theme.nord12; // orange
                            case "keybinds": return Theme.nord13;   // yellow
                            case "custom": return Theme.nord15;     // purple
                            default: return Theme.accent;
                        }
                    }
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
                    activeFocusOnTab: false
                    clip: true

                    onTextChanged: {
                        root.query = text;
                        root.updateFilter();
                    }

                    Keys.onUpPressed: {
                        if (root.selectedIndex > 0) root.selectedIndex--;
                        ensureVisible();
                    }
                    Keys.onDownPressed: {
                        if (root.selectedIndex < root.filteredItems.length - 1) root.selectedIndex++;
                        ensureVisible();
                    }
                    Keys.onReturnPressed: root.activateSelected()
                    Keys.onEnterPressed: root.activateSelected()
                    Keys.onEscapePressed: {
                        if (root.currentMode === "custom") {
                            FinderServer.resolveCancelled();
                        }
                        PanelState.closeAll();
                    }
                    Keys.onTabPressed: event => {
                        event.accepted = true;
                        root.cycleMode();
                    }
                }
            }
        }

        // ─── Match count ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tui.TuiText {
                text: root.filteredItems.length + "/" + getSourceItems().length
                textColor: Theme.nord7  // teal for count
                font.pixelSize: Theme.fontSizeSmall
            }

            Item { Layout.fillWidth: true }

            Tui.TuiText {
                visible: root.query !== ""
                text: "matching: \"" + root.query + "\""
                textColor: Theme.textMuted
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
            }
        }

        // ─── Results list ────────────────────────────────────────────
        Flickable {
            id: resultsFlickable
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
                    model: root.filteredItems

                    Item {
                        id: resultItem
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: resultRow.implicitHeight + 6

                        readonly property bool isSelected: index === root.selectedIndex

                        // Selection background
                        Rectangle {
                            anchors.fill: parent
                            visible: resultItem.isSelected
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.bgHover }
                                GradientStop { position: 0.7; color: Theme.bgElevated }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: !resultItem.isSelected && resultMouse.containsMouse
                            color: Theme.bgElevated
                        }

                        RowLayout {
                            id: resultRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 8

                            // Selection indicator
                            Tui.TuiText {
                                text: resultItem.isSelected ? ">" : " "
                                textColor: Theme.nord7  // teal for selection cursor
                                font.bold: true
                            }

                            // Name with match highlighting
                            Text {
                                text: resultItem.modelData.nameHtml || root.escapeHtml(resultItem.modelData.name)
                                textFormat: Text.RichText
                                color: resultItem.isSelected ? Theme.textBright : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: resultItem.isSelected
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Subtitle (comment/description)
                            Text {
                                visible: resultItem.modelData.subtitle !== ""
                                text: {
                                    if (resultItem.modelData.subtitleHtml) {
                                        return resultItem.modelData.subtitleHtml;
                                    }
                                    const s = resultItem.modelData.subtitle || "";
                                    const truncated = s.length > 30 ? s.substring(0, 30) + "…" : s;
                                    return root.escapeHtml(truncated);
                                }
                                textFormat: Text.RichText
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.italic: true
                                Layout.maximumWidth: 160
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: resultMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = resultItem.index;
                                root.activateSelected();
                            }
                        }
                    }
                }
            }
        }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: {
                switch (root.currentMode) {
                    case "apps": return "↑↓:navigate  enter:launch  tab:mode  esc:close";
                    case "screenshot": return "↑↓:navigate  enter:capture  tab:mode  esc:close";
                    case "keybinds": return "↑↓:navigate  tab:mode  esc:close";
                    case "custom": return "↑↓:navigate  enter:select  esc:cancel";
                }
            }
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    // ─── Scroll helper ───────────────────────────────────────────────
    function ensureVisible() {
        // Approximate item height and scroll to keep selected visible
        const itemHeight = 26;  // approximate row height
        const viewHeight = resultsFlickable.height;
        const targetY = root.selectedIndex * itemHeight;

        if (targetY < resultsFlickable.contentY) {
            resultsFlickable.contentY = targetY;
        } else if (targetY + itemHeight > resultsFlickable.contentY + viewHeight) {
            resultsFlickable.contentY = targetY + itemHeight - viewHeight;
        }
    }
}
