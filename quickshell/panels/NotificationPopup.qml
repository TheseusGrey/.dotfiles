import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.services
import qs.components as Tui

// Notification popup/toast — shows brief notifications that auto-dismiss.
// Appears as a small floating panel anchored top-right (below top bar).
// Stacks multiple notifications vertically (max 3 visible).
// Click to dismiss; critical notifications persist until clicked.
//
// Chrome mirrors the finder popup: each toast is a TuiPanel frame (4px
// border, same as the panels/rails) with a hard offset shadow beneath it
// (matching hyprland decoration.shadow, see FinderPopup.qml). The header
// row (urgency dot + app name) sits fully inside the border.
PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true

    margins.top: Theme.topPanelHeight + 8
    margins.right: (PanelState.rightPanelContext !== "" ? Theme.rightPanelExpanded : Theme.rightPanelCollapsed) + 8

    // Extra width reserves room for the hard rightward shadow.
    readonly property int shadowOffsetX: 10
    readonly property int shadowOffsetY: 10
    readonly property color shadowColor: "#bf000000"  // matches hyprland shadow_color default

    implicitWidth: 320 + shadowOffsetX
    implicitHeight: Math.max(1, popupColumn.implicitHeight + Theme.panelPadding * 2)

    exclusionMode: ExclusionMode.Ignore
    visible: popupModel.count > 0 && PanelState.rightPanelContext !== "notifications"
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-notification-popup"

    // ─── Popup queue model ───────────────────────────────────────────
    ListModel {
        id: popupModel
        // Each entry: { notifId, appName, summary, body, timestamp, urgency }
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
                timestamp: Date.now(),
                urgency: notification.urgency
            };
            popupModel.append(entry);
        }
    }

    // ─── Auto-dismiss timer (checks every second) ────────────────────
    // Critical notifications persist until the user dismisses them.
    Timer {
        id: dismissTimer
        interval: 1000
        repeat: true
        running: popupModel.count > 0

        onTriggered: {
            const now = Date.now();
            const timeout = 5000;  // 5 seconds per notification
            // Remove expired non-critical popups anywhere in the stack
            for (let i = 0; i < popupModel.count;) {
                const entry = popupModel.get(i);
                const critical = entry.urgency === NotificationUrgency.Critical;
                if (!critical && now - entry.timestamp > timeout) {
                    popupModel.remove(i);
                } else {
                    i++;
                }
            }
        }
    }

    // ─── Visual layout ───────────────────────────────────────────────
    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        anchors.leftMargin: Theme.panelPadding
        anchors.rightMargin: Theme.panelPadding
        anchors.topMargin: Theme.panelPadding
        anchors.bottomMargin: Theme.panelPadding
        spacing: 6

        Repeater {
            model: popupModel

            // ─── Single popup item (finder-style frame + hard shadow) ──
            Item {
                id: popupItem
                required property int index
                required property string appName
                required property string summary
                required property string body
                required property int urgency

                readonly property color levelColor: Theme.urgencyColor(urgency)

                Layout.fillWidth: true
                // Leave room for the hard downward/rightward shadow.
                Layout.bottomMargin: root.shadowOffsetY
                Layout.rightMargin: root.shadowOffsetX
                implicitHeight: popupContent.implicitHeight + (Theme.borderWidth + Theme.panelPadding) * 2

                // Hard shadow: solid offset block behind the frame (radius 0, no blur).
                Rectangle {
                    id: shadowBase
                    x: root.shadowOffsetX
                    y: root.shadowOffsetY
                    width: popupItem.width
                    height: popupItem.height
                    color: root.shadowColor
                }

                // ─── Toast frame (shell chrome) ───────────────────────
                Tui.TuiPanel {
                    anchors.fill: parent

                    ColumnLayout {
                        id: popupContent
                        anchors.fill: parent
                        spacing: 2

                        // App name + close hint
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Tui.TuiText {
                                text: Theme.dotFilled
                                textColor: popupItem.levelColor
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Tui.TuiText {
                                text: popupItem.appName
                                textColor: popupItem.levelColor
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

                // Click to dismiss (also handles the close hint)
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (popupItem.index >= 0 && popupItem.index < popupModel.count) {
                            popupModel.remove(popupItem.index);
                        }
                    }
                }
            }
        }
    }
}