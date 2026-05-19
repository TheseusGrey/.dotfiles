import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.widgets

// Popup notifications that appear briefly when new notifications arrive
PanelWindow {
    id: popup
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    implicitWidth: 360
    implicitHeight: popupColumn.implicitHeight + 24
    visible: popupModel.count > 0

    exclusionMode: ExclusionMode.Ignore

    ListModel {
        id: popupModel
    }

    property int lastCount: 0

    Connections {
        target: NotificationManager.server
        function onNotification(notification) {
            let timeout = notification.expireTimeout > 0 ? notification.expireTimeout : 5000;
            popupModel.append({
                "notifId": notification.id,
                "summary": notification.summary ?? "",
                "body": notification.body ?? "",
                "appName": notification.appName ?? "",
                "timeout": timeout
            });
            removeTimer.createObject(popup, { "targetId": notification.id, "interval": timeout });

            // Auto-expire: dismiss from server after timeout if transient
            if (notification.expireTimeout > 0) {
                expireTimer.createObject(popup, { "notif": notification, "interval": notification.expireTimeout });
            }
        }
    }

    Component {
        id: expireTimer
        Timer {
            required property var notif
            running: true
            repeat: false
            onTriggered: {
                notif.expire();
                destroy();
            }
        }
    }

    Component {
        id: removeTimer
        Timer {
            required property int targetId
            running: true
            repeat: false
            onTriggered: {
                for (let i = 0; i < popupModel.count; i++) {
                    if (popupModel.get(i).notifId === targetId) {
                        popupModel.remove(i);
                        break;
                    }
                }
                destroy();
            }
        }
    }

    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        Repeater {
            model: popupModel

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: popupContent.implicitHeight + 16
                color: Theme.bg
                border.color: Theme.border
                border.width: 1

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.shadow
                    shadowBlur: 0.4
                    shadowVerticalOffset: 2
                }

                ColumnLayout {
                    id: popupContent
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Text {
                        text: (model.appName ? "[" + model.appName + "] " : "") + model.summary
                        color: Theme.fg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                    Text {
                        visible: model.body !== ""
                        text: model.body
                        color: Theme.fgDim
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        for (let i = 0; i < popupModel.count; i++) {
                            if (popupModel.get(i).notifId === model.notifId) {
                                popupModel.remove(i);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}
