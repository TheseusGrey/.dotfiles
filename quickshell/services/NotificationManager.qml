pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property alias server: _server
    readonly property var notifications: _server.trackedNotifications
    readonly property int count: _server.trackedNotifications.values.length

    // Signal emitted for each new notification (for popup/toast system)
    signal notificationPosted(var notification)

    NotificationServer {
        id: _server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
    }

    Connections {
        target: _server
        function onNotification(notification) {
            notification.tracked = true;
            root.notificationPosted(notification);
        }
    }

    function clearAll() {
        const notifs = _server.trackedNotifications.values;
        for (let i = notifs.length - 1; i >= 0; i--) {
            notifs[i].dismiss();
        }
    }

    function dismiss(notification) {
        notification.dismiss();
    }
}
