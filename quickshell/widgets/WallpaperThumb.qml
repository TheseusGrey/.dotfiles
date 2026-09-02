import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components as Tui

// One wallpaper card in the theme switcher: a 16:9 image preview with a
// derived-accent colour bar underneath (bg / primary / secondary / tertiary)
// and the filename label. Clicking applies the wallpaper via `qsh wallpaper`.
//
// Derived accents come from `qsh accent <name>` (matugen --dry-run, no side
// effects). Until that resolves the bar shows a dimmed placeholder.
Item {
    id: root

    property string fileName: ""
    property real barHeight: 5
    signal applied()

    readonly property string src: "file:///home/ashe/.dotfiles/wallpapers/" + fileName

    // ─── Derived accent colours (populated async) ─────────────────────
    property string colBg: Theme.bgElevated
    property string colPrimary: Theme.border
    property string colSecondary: Theme.border
    property string colTertiary: Theme.border

    implicitWidth: 160
    implicitHeight: 110

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        // ─── Image preview (16:9) ────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.width * 0.5625

            Rectangle {
                anchors.fill: parent
                color: Theme.bgElevated
                border.width: 1
                border.color: root.hovered ? Theme.accent : Theme.borderFaint
            }

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: root.src
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 256
            }

            // derived-accent bar (bg / primary / secondary / tertiary)
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.barHeight

                Rectangle { color: root.colBg;        width: parent.width * 0.25 }
                Rectangle { color: root.colPrimary;   width: parent.width * 0.25 }
                Rectangle { color: root.colSecondary; width: parent.width * 0.25 }
                Rectangle { color: root.colTertiary;  width: parent.width * 0.25 }
            }
        }

        // ─── Filename label ──────────────────────────────────────────
        Tui.TuiText {
            Layout.fillWidth: true
            text: root.fileName
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Full-card hover/click overlay, drawn above the layout (so it isn't
    // layout-managed). Accepts no buttons to let nothing below be blocked.
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.applied()
    }

    readonly property bool hovered: mouse.containsMouse

    // ─── Async accent derivation ────────────────────────────────────
    Process {
        id: accentProc
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => { accentProc.buffer += data + "\n"; }
        }

        onRunningChanged: {
            if (!running) {
                const parts = accentProc.buffer.trim().split(/\s+/);
                if (parts.length >= 4) {
                    root.colBg = parts[0];
                    root.colPrimary = parts[1];
                    root.colSecondary = parts[2];
                    root.colTertiary = parts[3];
                }
            }
        }
    }

    Component.onCompleted: {
        accentProc.command = ["/home/ashe/.local/bin/qsh", "accent", root.fileName];
        accentProc.running = true;
    }
}