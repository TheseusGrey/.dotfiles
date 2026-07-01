import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components as Tui

// Notification popup/toast — shows brief notifications that auto-dismiss.
// Appears as a small floating panel anchored top-right (below top bar).
// Stacks multiple notifications vertically (max 3 visible).
// Click to dismiss, auto-fades after timeout.
PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true

    margins.top: Theme.topPanelHeight + 8
    margins.right: 8

    implicitWidth: 320
    implicitHeight: Math.max(1, popupColumn.implicitHeight + Theme.panelPadding * 2)

    exclusionMode: ExclusionMode.Ignore
    visible: popupModel.count > 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-notification-popup"

    // ─── Popup queue model ───────────────────────────────────────────
    ListModel {
        id: popupModel
        // Each entry: { notifId, appName, summary, body, timestamp }
    }

    // ─── Listen for new notifications ────────────────────────────────
    Connections {
        target: NotificationManager
        function onNotificationPosted(notification) {
            // Limit to 3 visible popups
            if (popupModel.count >= 3) {
                popupModel.remove(0);
            }

            const entry = {
                notifId: Date.now(),
                appName: notification.appName || "notification",
                summary: notification.summary || "",
                body: notification.body || "",
                timestamp: Date.now()
            };
            popupModel.append(entry);
        }
    }

    // ─── Auto-dismiss timer (checks every second) ────────────────────
    Timer {
        id: dismissTimer
        interval: 1000
        repeat: true
        running: popupModel.count > 0

        onTriggered: {
            const now = Date.now();
            const timeout = 5000;  // 5 seconds per notification
            // Remove expired popups from the front
            while (popupModel.count > 0) {
                const entry = popupModel.get(0);
                if (now - entry.timestamp > timeout) {
                    popupModel.remove(0);
                } else {
                    break;
                }
            }
        }
    }

    // ─── Visual layout ───────────────────────────────────────────────
    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        anchors.margins: Theme.panelPadding
        spacing: 6

        Repeater {
            model: popupModel

            // ─── Single popup item ───────────────────────────────────
            Rectangle {
                id: popupItem
                required property int index
                required property string appName
                required property string summary
                required property string body

                Layout.fillWidth: true
                implicitHeight: popupContent.implicitHeight + 12
                color: Theme.nord1
                border.width: 1
                border.color: Theme.border
                radius: 0

                // Click to dismiss
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (popupItem.index >= 0 && popupItem.index < popupModel.count) {
                            popupModel.remove(popupItem.index);
                        }
                    }
                }

                ColumnLayout {
                    id: popupContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 2

                    // App name + close hint
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Tui.TuiText {
                            text: Theme.dotFilled
                            textColor: Theme.accent
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Tui.TuiText {
                            text: popupItem.appName
                            textColor: Theme.accent
                            font.bold: true
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Item { Layout.fillWidth: true }

                        Tui.TuiText {
                            text: "×"
                            textColor: Theme.textMuted
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    // Summary (bold)
                    Tui.TuiText {
                        visible: popupItem.summary !== ""
                        text: {
                            const s = popupItem.summary;
                            return s.length > 40 ? s.substring(0, 39) + "…" : s;
                        }
                        textColor: Theme.textPrimary
                        font.bold: true
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.fillWidth: true
                    }

                    // Body (muted, truncated)
                    Tui.TuiText {
                        visible: popupItem.body !== ""
                        text: {
                            const b = popupItem.body;
                            return b.length > 60 ? b.substring(0, 59) + "…" : b;
                        }
                        textColor: Theme.textMuted
                        font.pixelSize: Theme.fontSizeSmall
                        font.italic: true
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
