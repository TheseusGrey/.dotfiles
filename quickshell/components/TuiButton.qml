import QtQuick
import qs.services
import qs.components as Tui

// Clickable text/glyph button with TUI states.
// States: idle / hover / active / disabled. `inverse` renders as an inverted
// block (accent background, dark text) which is how focused menu items look.
// Uses the monospace cell grid so rows align across surfaces.

Item {
    id: root

    property string text: ""
    property string variant: "body"
    property int fontSize: 0
    property int textAlign: Text.AlignHCenter
    property color normalColor: Theme.textPrimary
    property color hoverColor: Theme.textBright
    property color activeColor: Theme.accent
    property color disabledColor: Theme.textMuted
    property bool active: false
    property bool disabled: false
    property bool inverse: false

    signal clicked()

    readonly property bool hovered: mouse.containsMouse

    // Cell-snapped height: one text line tall, two chars wide minimum.
    implicitWidth: Math.max(Tui.TuiMetrics.cellWidth * 2, textItem.implicitWidth + Tui.TuiMetrics.cellWidth * 2)
    implicitHeight: Tui.TuiMetrics.lineHeight

    // Background: hover uses a subtle elevated fill; inverse uses the accent.
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 0
        color: root.inverse ? Theme.accent
            : (root.active ? Theme.bgHover : root.hovered ? Theme.bgHover : "transparent")
    }

    // Left accent notch for active state (blocky active marker)
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 0
        color: Theme.accent
        visible: root.active && !root.inverse
    }

    Tui.TuiText {
        id: textItem
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        variant: root.variant
        fontSize: root.fontSize
        horizontalAlignment: root.textAlign
        elide: Text.ElideRight

        // Foreground depends on state.
        color: {
            if (root.disabled) return root.disabledColor;
            if (root.inverse) return Theme.onAccent;
            if (root.active) return root.activeColor;
            if (root.hovered) return root.hoverColor;
            return root.normalColor;
        }
        font.bold: root.inverse || root.active || root.hovered
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}