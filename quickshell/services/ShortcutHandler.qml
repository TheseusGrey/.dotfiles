pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // IPC handler: receives commands from hyprland keybinds via:
    //   qs ipc call shell <function>
    // e.g. bind = SUPER, SPACE, exec, qs ipc call shell toggleFinder
    IpcHandler {
        target: "shell"

        function toggleLeft(): void {
            PanelState.toggleLeft();
        }

        function toggleVolume(): void {
            PanelState.openRight("volume");
        }

        function toggleBrightness(): void {
            PanelState.openRight("brightness");
        }

        function toggleWifi(): void {
            PanelState.openRight("wifi");
        }

        function toggleBluetooth(): void {
            PanelState.openRight("bluetooth");
        }

        function togglePower(): void {
            PanelState.openRight("power");
        }

        function toggleNotifications(): void {
            PanelState.openRight("notifications");
        }

        function toggleFinder(): void {
            PanelState.openRight("finder");
        }

        function toggleKeybinds(): void {
            PanelState.openRight("keybinds");
        }

        function closeAll(): void {
            PanelState.closeAll();
        }

        function dismissNotifications(): void {
            NotificationManager.clearAll();
        }

        // OSD triggers — called from keybind scripts after adjusting volume/brightness
        // Usage: qs ipc call shell osdVolume 0.75 false
        //        qs ipc call shell osdBrightness 0.50
        function osdVolume(level: real, muted: bool): void {
            PanelState.showOsd("volume", level, muted || false);
        }

        function osdBrightness(level: real): void {
            PanelState.showOsd("brightness", level, false);
        }

        function lock(): void {
            PanelState.requestLock();
        }
    }
}
