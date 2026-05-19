import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.widgets

PanelWindow {
    id: panel
    color: "transparent"

    anchors {
        bottom: true
        left: true
        right: true
    }

    property bool hovered: false
    property bool expanded: hovered || PanelState.activePanel === "bottom"
    implicitHeight: expanded ? 400 : Theme.borderThickness

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.borderThickness

    // All apps from .desktop scan
    property var allApps: []
    // Filtered subset
    property var filteredApps: []

    function filterApps(query) {
        if (!query) {
            filteredApps = allApps;
        } else {
            let q = query.toLowerCase();
            filteredApps = allApps.filter(app =>
                app.name.toLowerCase().indexOf(q) !== -1 ||
                app.exec.toLowerCase().indexOf(q) !== -1 ||
                app.comment.toLowerCase().indexOf(q) !== -1
            );
        }
        appList.currentIndex = 0;
    }

    function launch(exec) {
        launchProc.command = ["sh", "-c", exec + " &"];
        launchProc.running = true;
        panel.expanded = false;
    }

    Process {
        id: launchProc
        property var command: ["true"]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onContainsMouseChanged: panel.hovered = containsMouse
        onPressed: (mouse) => mouse.accepted = false
        onReleased: (mouse) => mouse.accepted = false
    }

    // Collapsed
    Rectangle {
        anchors.fill: parent
        color: Theme.border
        visible: !panel.expanded
    }

    // Expanded: launcher
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        visible: panel.expanded
        border.color: Theme.border
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 0.3
            shadowVerticalOffset: -2
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            // Search input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: Theme.bgAlt
                border.color: Theme.border
                border.width: 1

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    clip: true

                    onTextChanged: panel.filterApps(text)

                    Keys.onDownPressed: {
                        if (appList.currentIndex < panel.filteredApps.length - 1)
                            appList.currentIndex++;
                    }
                    Keys.onUpPressed: {
                        if (appList.currentIndex > 0)
                            appList.currentIndex--;
                    }
                    Keys.onReturnPressed: {
                        if (panel.filteredApps.length > 0) {
                            panel.launch(panel.filteredApps[appList.currentIndex].exec);
                        }
                    }
                    Keys.onEscapePressed: {
                        PanelState.close();
                        panel.hovered = false;
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "> search..."
                        color: Theme.fgDim
                        font: parent.font
                        visible: !parent.text
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Results count
            Text {
                text: panel.filteredApps.length + " entries"
                color: Theme.fgDim
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
            }

            // App list
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 0
                currentIndex: 0
                highlightMoveDuration: 50

                model: panel.filteredApps.length

                delegate: Rectangle {
                    required property int index
                    width: appList.width
                    height: 28
                    color: index === appList.currentIndex ? Theme.bgAlt : (delegateMouse.containsMouse ? Theme.bgAlt : "transparent")

                    property var app: panel.filteredApps[index] || { name: "", exec: "", comment: "" }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 8

                        Text {
                            text: index === appList.currentIndex ? ">" : " "
                            color: Theme.accent
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: app.name
                            color: Theme.fg
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: app.comment
                            color: Theme.fgDim
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: panel.launch(app.exec)
                        onContainsMouseChanged: {
                            if (containsMouse) appList.currentIndex = index;
                        }
                    }
                }
            }
        }

        // Focus management on expand
        onVisibleChanged: {
            if (visible) {
                searchInput.text = "";
                searchInput.forceActiveFocus();
                if (panel.allApps.length === 0) {
                    desktopScanner.running = true;
                }
            }
        }
    }

    // Desktop file scanner - runs list-apps.sh, parses JSON lines
    Process {
        id: desktopScanner
        command: [Qt.resolvedUrl("../scripts/list-apps.sh").toString().replace("file://", "")]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    let app = JSON.parse(line);
                    if (app.name && app.exec) {
                        panel.allApps.push(app);
                    }
                } catch(e) {}
            }
        }
        onRunningChanged: {
            if (!running && panel.allApps.length > 0) {
                // Sort alphabetically
                panel.allApps.sort((a, b) => a.name.localeCompare(b.name));
                panel.filterApps(searchInput.text);
            }
        }
    }

    // Refresh timer - rescan every 60s
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            panel.allApps = [];
            desktopScanner.running = true;
        }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
    }
}
