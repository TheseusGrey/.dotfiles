import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.theme

Rectangle {
    width: 28
    height: 28
    color: powerMouse.containsMouse ? Theme.bgAlt : "transparent"
    border.color: powerMouse.containsMouse ? Theme.border : "transparent"
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: "⏻"
        color: Theme.error
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamily
    }

    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: powerMenu.visible = !powerMenu.visible
    }

    // Power menu popup
    Rectangle {
        id: powerMenu
        visible: false
        width: 160
        height: menuCol.implicitHeight + 12
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.right: parent.right
        z: 100

        Column {
            id: menuCol
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0

            Repeater {
                model: [
                    { label: " lock", cmd: "loginctl lock-session" },
                    { label: "󰗽 logout", cmd: "hyprctl dispatch exit" },
                    { label: " reboot", cmd: "systemctl reboot" },
                    { label: "⏻ shutdown", cmd: "systemctl poweroff" }
                ]

                Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 26
                    color: itemMouse.containsMouse ? Theme.bgAlt : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: itemMouse.containsMouse ? Theme.accent : Theme.fg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            powerMenu.visible = false;
                            proc.command = modelData.cmd.split(" ");
                            proc.running = true;
                        }
                    }
                }
            }
        }
    }

    Process {
        id: proc
        property var command: []
        running: false
    }
}
