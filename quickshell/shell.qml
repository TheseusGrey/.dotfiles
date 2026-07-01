import QtQuick
import Quickshell
import qs.panels as Panels
import qs.services

// Shell entry point.
// Loads all panels and ensures singletons are initialized.
ShellRoot {
    Panels.TopPanel {}
    Panels.LeftPanel {}
    Panels.RightPanel {}
    Panels.OsdOverlay {}
    Panels.LockScreen {}

    // Force singleton initialization (they have no visual component)
    Component.onCompleted: {
        // ShortcutHandler registers the IPC handler on creation
        void(ShortcutHandler);
        void(NotificationManager);
    }
}
