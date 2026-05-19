import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.theme
import qs.panels
import qs.widgets

ShellRoot {
    // Force singleton initialization
    property var _shortcutHandler: ShortcutHandler
    property var _panelState: PanelState

    TopBar {}
    BottomBorder {}
    LeftBorder {}
    RightBorder {}
    NotificationPopup {}
}
