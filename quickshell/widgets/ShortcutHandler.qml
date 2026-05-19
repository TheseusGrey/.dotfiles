pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // IPC handler: receives commands from hyprland keybinds via:
    //   quickshell ipc <command>
    // e.g. bind = SUPER, SPACE, exec, quickshell msg toggle-launcher
    IpcHandler {
        function handleMessage(message) {
            switch (message.trim()) {
            case "toggle-launcher":
                PanelState.toggle("bottom");
                break;
            case "toggle-notifications":
                PanelState.toggle("right");
                break;
            case "toggle-obsidian":
                PanelState.toggle("left");
                break;
            case "toggle-power":
                PanelState.toggle("top");
                break;
            case "close-panel":
                PanelState.close();
                break;
            case "dismiss-notifications":
                PanelState.dismissAllNotifications();
                break;
            default:
                return "unknown command: " + message;
            }
            return "ok";
        }
    }
}
