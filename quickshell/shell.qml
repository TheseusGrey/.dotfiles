import QtQuick
import Quickshell
import Quickshell.Io
import qs.panels as Panels
import qs.services

// Shell entry point.
// Loads all panels and ensures singletons are initialized.
ShellRoot {
    // Kill dunst on startup so quickshell's NotificationServer can own the D-Bus name.
    // Only one notification daemon can hold org.freedesktop.Notifications at a time.
    Process {
        id: killDunst
        command: ["pkill", "-x", "dunst"]
        running: true
    }

    Panels.TopPanel {}
    Panels.LeftPanel {}
    Panels.RightPanel {}
    Panels.BottomBorder {}
    Panels.NotificationPopup {}
    Panels.OsdOverlay {}
    Panels.LockScreen {}

    // Force singleton initialization (they have no visual component)
    Component.onCompleted: {
        // ShortcutHandler registers the IPC handler on creation
        void(ShortcutHandler);
        void(NotificationManager);
    }
}
