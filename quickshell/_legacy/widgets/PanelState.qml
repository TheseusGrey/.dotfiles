pragma Singleton

import Quickshell
import QtQuick
import qs.widgets

Singleton {
    id: root

    // Which panel is currently keyboard-toggled open (empty = none)
    // Values: "top", "bottom", "left", "right", ""
    property string activePanel: ""

    function toggle(panel) {
        if (activePanel === panel) {
            activePanel = "";
        } else {
            activePanel = panel;
        }
    }

    function close() {
        activePanel = "";
    }

    function dismissAllNotifications() {
        NotificationManager.clearAll();
    }
}
