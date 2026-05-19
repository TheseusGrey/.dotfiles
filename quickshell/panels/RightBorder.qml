import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.widgets

PanelWindow {
    id: panel
    color: "transparent"

    anchors {
        right: true
        top: true
        bottom: true
    }

    property bool hovered: false
    property bool expanded: hovered || PanelState.activePanel === "right"
    implicitWidth: expanded ? Theme.expandedPanelWidth : Theme.borderThickness

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.borderThickness

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

    // Expanded: notification tray
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
            shadowHorizontalOffset: -2
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "── notifications ──"
                    color: Theme.fgDim
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: NotificationManager.notifications.length + " items"
                    color: Theme.fgDim
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                }
                Item { width: 8 }
                Rectangle {
                    width: 56
                    height: 24
                    color: clearMouse.containsMouse ? Theme.bgAlt : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "[clear]"
                        color: clearMouse.containsMouse ? Theme.accent : Theme.fgDim
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: NotificationManager.clearAll()
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Notification list
            ListView {
                id: notifList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: NotificationManager.notifications

                delegate: Rectangle {
                    required property var modelData
                    width: notifList.width
                    height: notifContent.implicitHeight + 16
                    color: delegateMouse.containsMouse ? Theme.bgAlt : Theme.bg
                    border.color: Theme.border
                    border.width: 1

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    ColumnLayout {
                        id: notifContent
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        // Title row with dismiss
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: (modelData.appName ? "[" + modelData.appName + "] " : "") + (modelData.summary ?? "")
                                color: Theme.fg
                                font.pixelSize: Theme.fontSize
                                font.family: Theme.fontFamily
                                font.bold: true
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            // Dismiss button
                            Rectangle {
                                width: 20
                                height: 20
                                color: dismissMouse.containsMouse ? Theme.error : "transparent"
                                border.color: dismissMouse.containsMouse ? Theme.error : Theme.border
                                border.width: 1
                                visible: delegateMouse.containsMouse

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: dismissMouse.containsMouse ? Theme.bg : Theme.fgDim
                                    font.pixelSize: Theme.fontSize
                                    font.family: Theme.fontFamily
                                }

                                MouseArea {
                                    id: dismissMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: modelData.dismiss()
                                }
                            }
                        }

                        // Body
                        Text {
                            visible: (modelData.body ?? "") !== ""
                            text: modelData.body ?? ""
                            color: Theme.fgDim
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }

                        // Actions
                        Row {
                            visible: modelData.actions && modelData.actions.length > 0
                            spacing: 6
                            Layout.fillWidth: true

                            Repeater {
                                model: modelData.actions ?? []

                                Rectangle {
                                    required property var modelData
                                    width: actionText.implicitWidth + 12
                                    height: 22
                                    color: actionMouse.containsMouse ? Theme.bgAlt : "transparent"
                                    border.color: Theme.border
                                    border.width: 1

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: "[" + modelData.label + "]"
                                        color: actionMouse.containsMouse ? Theme.accent : Theme.fgDim
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.family: Theme.fontFamily
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            Text {
                visible: NotificationManager.notifications.length === 0
                text: "~ no notifications ~"
                color: Theme.fgDim
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad }
    }
}
