import QtQuick
import QtQuick.Layouts
import qs.services

// Renders a TUI-style rounded border using box-drawing characters.
// Content goes inside via the `content` default property.
//
// Visual result:
//   ╭─ title ──────╮
//   │ content here  │
//   ╰──────────────╯
//
// The border is drawn as Text elements positioned around the content area.
// This gives an authentic terminal look without Qt's rectangle borders.

Item {
    id: root

    property string title: ""
    property color borderColor: Theme.border
    property color titleColor: Theme.accent
    default property alias content: contentArea.data

    // Internal: character width for the monospace font at current size
    readonly property real charWidth: metrics.advanceWidth

    TextMetrics {
        id: metrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        text: "─"
    }

    // ─── Top border ─────────────────────────────────────────────────
    Text {
        id: topBorder
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: root.borderColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        elide: Text.ElideNone
        clip: true

        text: {
            const availWidth = Math.floor(root.width / root.charWidth);
            if (availWidth < 4) return Theme.boxTopLeft + Theme.boxTopRight;

            if (root.title === "") {
                const fill = Theme.boxHorizontal.repeat(Math.max(0, availWidth - 2));
                return Theme.boxTopLeft + fill + Theme.boxTopRight;
            }

            const titleStr = " " + root.title + " ";
            const titleLen = titleStr.length;
            const remaining = Math.max(0, availWidth - 2 - titleLen);
            const leftFill = Theme.boxHorizontal;
            const rightFill = Theme.boxHorizontal.repeat(remaining);
            return Theme.boxTopLeft + leftFill + titleStr + rightFill + Theme.boxTopRight;
        }
    }

    // Title overlay (colored differently from border)
    Text {
        visible: root.title !== ""
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: root.charWidth * 2
        color: root.titleColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        text: root.title
    }

    // ─── Left border ────────────────────────────────────────────────
    Column {
        id: leftBorder
        anchors.top: topBorder.bottom
        anchors.bottom: bottomBorder.top
        anchors.left: parent.left
        width: root.charWidth

        Repeater {
            model: Math.max(0, Math.floor(leftBorder.height / topBorder.implicitHeight))
            Text {
                color: root.borderColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                text: Theme.boxVertical
            }
        }
    }

    // ─── Right border ───────────────────────────────────────────────
    Column {
        id: rightBorder
        anchors.top: topBorder.bottom
        anchors.bottom: bottomBorder.top
        anchors.right: parent.right
        width: root.charWidth

        Repeater {
            model: Math.max(0, Math.floor(rightBorder.height / topBorder.implicitHeight))
            Text {
                color: root.borderColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                text: Theme.boxVertical
            }
        }
    }

    // ─── Bottom border ──────────────────────────────────────────────
    Text {
        id: bottomBorder
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: root.borderColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        clip: true

        text: {
            const availWidth = Math.floor(root.width / root.charWidth);
            if (availWidth < 4) return Theme.boxBottomLeft + Theme.boxBottomRight;
            const fill = Theme.boxHorizontal.repeat(Math.max(0, availWidth - 2));
            return Theme.boxBottomLeft + fill + Theme.boxBottomRight;
        }
    }

    // ─── Content area ───────────────────────────────────────────────
    Item {
        id: contentArea
        anchors.top: topBorder.bottom
        anchors.bottom: bottomBorder.top
        anchors.left: leftBorder.right
        anchors.right: rightBorder.left
        anchors.margins: Theme.panelPadding
    }
}
