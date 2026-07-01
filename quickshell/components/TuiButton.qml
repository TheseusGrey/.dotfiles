import QtQuick
import qs.services

// Clickable text button with TUI styling.
// Bold + accent color on hover, normal otherwise.
// Emits clicked() signal.

Item {
    id: root

    property string text: ""
    property color normalColor: Theme.textPrimary
    property color hoverColor: Theme.accent
    property color activeColor: Theme.accentSecondary
    property bool active: false
    property int fontSize: Theme.fontSize

    signal clicked()

    implicitWidth: buttonText.implicitWidth
    implicitHeight: buttonText.implicitHeight

    Text {
        id: buttonText
        anchors.fill: parent
        text: root.text
        color: root.active ? root.activeColor : mouseArea.containsMouse ? root.hoverColor : root.normalColor
        font.family: Theme.fontFamily
        font.pixelSize: root.fontSize
        font.bold: mouseArea.containsMouse || root.active
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
