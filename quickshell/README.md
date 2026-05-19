# Quickshell Config for Hyprland

Hover-to-expand border panels on all 4 screen edges with keyboard shortcut support.

## Structure

```
quickshell/
├── shell.qml                  # Entry point
├── theme/
│   ├── qmldir
│   ├── Theme.qml              # Singleton, hot-reloads theme.json via FileView
│   └── theme.json             # Colors, fonts, geometry, animation
├── panels/
│   ├── qmldir
│   ├── TopBar.qml             # Workspaces, active window, status, clock, power
│   ├── BottomBorder.qml       # App launcher (search + .desktop files)
│   ├── LeftBorder.qml         # Placeholder (future Obsidian integration)
│   ├── RightBorder.qml        # Notification tray
│   └── NotificationPopup.qml  # Transient popup overlay (top-right)
├── widgets/
│   ├── qmldir
│   ├── Workspaces.qml         # Hyprland workspace dots
│   ├── Clock.qml
│   ├── ActiveWindow.qml       # Hyprland active window title
│   ├── StatusIcons.qml        # Wifi/Bluetooth/Volume (reactive polling)
│   ├── PowerButton.qml        # Shutdown/reboot/lock/logout menu
│   ├── Launcher.qml           # Stub (logic lives in BottomBorder)
│   ├── NotificationManager.qml # Singleton wrapping NotificationServer
│   ├── PanelState.qml         # Singleton tracking keyboard-toggled panel
│   └── ShortcutHandler.qml    # IPC handler for keybind commands
├── components/
│   ├── qmldir
│   └── BorderPanel.qml        # Reusable base (not currently used)
└── scripts/
    └── list-apps.sh           # Scans .desktop files, outputs JSON lines
```

## How It Works

- Each edge is a `PanelWindow` that collapses to a 2px border (reserves exclusive zone)
- Hovering expands the panel with a 100ms animation
- Keyboard shortcuts can also toggle panels via IPC
- Only one panel can be keyboard-toggled at a time; hover works independently
- Theme is controlled by `theme/theme.json` and hot-reloaded on change

## Hyprland Keybinds

Add to your `hyprland.conf`:

```ini
bind = SUPER, SPACE, exec, quickshell msg toggle-launcher
bind = SUPER, N, exec, quickshell msg toggle-notifications
bind = SUPER, O, exec, quickshell msg toggle-obsidian
bind = SUPER SHIFT, Q, exec, quickshell msg toggle-power
bind = SUPER, D, exec, quickshell msg dismiss-notifications

# Optional: global escape (see caveats)
# bind = , ESCAPE, exec, quickshell msg close-panel
```

## Caveats

1. **IPC command syntax** — The `quickshell msg` command depends on your quickshell-git version. It may be `quickshell ipc`, `quickshell msg`, or require a socket path. Check `quickshell --help`.

2. **Global Escape bind** — Binding bare Escape globally will intercept it in all applications. The launcher's TextInput already handles Escape locally when focused. Consider using a Hyprland submap or omitting the global bind entirely.

3. **Status icons are poll-based** — WiFi/Bluetooth/Volume use `Process` + `SplitParser` polling (2-5s intervals). They require `nmcli`, `bluetoothctl`, and `wpctl` to be installed.

4. **NotificationServer replaces dunst/mako** — Running this config means Quickshell owns the notification bus. Stop any other notification daemon first.

5. **Launcher path resolution** — `list-apps.sh` is resolved via `Qt.resolvedUrl("../scripts/list-apps.sh")`. If quickshell is launched from a different working directory, the path may not resolve correctly. Hardcode the absolute path if needed.

6. **Requires quickshell-git** — The Hyprland IPC APIs (`Quickshell.Hyprland`), `NotificationServer`, `IpcHandler`, and `FileView` are from the git/development version, not stable releases.

7. **Single monitor only** — Panels are not wrapped in `Variants` with `Quickshell.screens`. They attach to the default screen.

8. **`onNotification` signal** — The NotificationPopup connects to the server's notification signal. The exact signal name may differ across quickshell-git versions; adjust if popups don't appear.
