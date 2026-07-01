import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.components as Tui

// Notification list panel — shows tracked notifications with interactivity.
// - Empty state: placeholder at top ("○ no notifications")
// - Each notification: app name (bold), body (dim), close button
// - Click notification body to focus the source app
// - "clear all" button at bottom when notifications exist
Item {
    id: root

    readonly property var notifications: NotificationManager.notifications
    readonly property bool hasNotifications: NotificationManager.count > 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Header info ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tui.TuiText {
                text: root.hasNotifications ? NotificationManager.count + " notification" + (NotificationManager.count > 1 ? "s" : "") : ""
                textColor: Theme.textPrimary
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Clear all button (only when notifications exist)
            Tui.TuiButton {
                visible: root.hasNotifications
                text: "[clear all]"
                activeColor: Theme.error
                onClicked: NotificationManager.clearAll()
            }
        }

        Item { Layout.preferredHeight: Theme.itemSpacing }

        // ─── Empty state ─────────────────────────────────────────────
        Item {
            visible: !root.hasNotifications
            Layout.fillWidth: true
            Layout.preferredHeight: emptyLayout.implicitHeight + 16

            RowLayout {
                id: emptyLayout
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 8
                spacing: 8

                Tui.TuiText {
                    text: Theme.dotEmpty
                    textColor: Theme.textMuted
                }

                Tui.TuiText {
                    text: "no notifications"
                    textColor: Theme.textMuted
                    font.italic: true
                }
            }
        }

        // ─── Notification list ───────────────────────────────────────
        // Use a Flickable for scrolling when list is long
        Flickable {
            visible: root.hasNotifications
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: notifColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: notifColumn
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.notifications.values

                    // ─── Single notification item ─────────────────────
                    Item {
                        id: notifItem
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: notifContent.implicitHeight + 12

                        readonly property string appName: modelData.appName || "unknown"
                        readonly property string body: modelData.body || ""
                        readonly property string summary: modelData.summary || ""

                        // Background highlight on hover
                        Rectangle {
                            anchors.fill: parent
                            color: notifMouse.containsMouse ? Theme.bgHover : "transparent"
                            radius: 0
                        }

                        ColumnLayout {
                            id: notifContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 2

                            // Top row: app name + close button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                // Dot indicator
                                Tui.TuiText {
                                    text: Theme.dotFilled
                                    textColor: Theme.accent
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                // App name
                                Tui.TuiText {
                                    text: notifItem.appName
                                    textColor: Theme.accent
                                    font.bold: true
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                Item { Layout.fillWidth: true }

                                // Close button
                                Tui.TuiButton {
                                    text: "×"
                                    activeColor: Theme.error
                                    fontSize: Theme.fontSize
                                    onClicked: NotificationManager.dismiss(notifItem.modelData)
                                }
                            }

                            // Summary (if present, bold)
                            Tui.TuiText {
                                visible: notifItem.summary !== ""
                                text: {
                                    const s = notifItem.summary;
                                    return s.length > 50 ? s.substring(0, 50) + "…" : s;
                                }
                                textColor: Theme.textPrimary
                                font.bold: true
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.fillWidth: true
                            }

                            // Body text (dimmer, italic, wrapped)
                            Tui.TuiText {
                                visible: notifItem.body !== ""
                                text: {
                                    const b = notifItem.body;
                                    return b.length > 120 ? b.substring(0, 120) + "…" : b;
                                }
                                textColor: Theme.textMuted
                                font.pixelSize: Theme.fontSizeSmall
                                font.italic: true
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            // Separator line between notifications
                            Tui.TuiText {
                                text: Theme.boxHorizontal.repeat(30)
                                textColor: Theme.border
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.topMargin: 4
                            }
                        }

                        MouseArea {
                            id: notifMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Try to focus the app that sent the notification
                                // Invoke default action if available
                                if (notifItem.modelData.actions && notifItem.modelData.actions.length > 0) {
                                    notifItem.modelData.actions[0].invoke();
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── Spacer ─────────────────────────────────────────────────
        Item { Layout.fillHeight: !root.hasNotifications }

        // ─── Help bar ────────────────────────────────────────────────
        Tui.TuiText {
            text: root.hasNotifications ? "click:action  ×:dismiss" : "notifications will appear here"
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
            Layout.topMargin: Theme.itemSpacing
        }
    }
}
