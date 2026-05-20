pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property alias server: _server
    readonly property var notifications: _server.notifications

    NotificationServer {
        id: _server
        keepOnReload: true
    }

    function clearAll() {
        for (let i = notifications.length - 1; i >= 0; i--) {
            notifications[i].dismiss();
        }
    }
}
