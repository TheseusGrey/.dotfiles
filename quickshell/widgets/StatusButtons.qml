import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components as Tui

// Status buttons row — clickable NerdFont icons that trigger the right panel.
// Each icon opens a different context in the right panel.
// Active state: accent color + bold. Inactive: textPrimary. Hover: textBright.
RowLayout {
    id: root
    spacing: Theme.itemSpacing

    // Detect wired connectivity for network icon
    property bool hasEthernet: false

    Process {
        id: netCheckProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                netCheckProc.buffer += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                root.hasEthernet = netCheckProc.buffer.indexOf("ethernet:connected") !== -1;
                netCheckProc.buffer = "";
                netCheckTimer.start();
            }
        }
    }

    Timer {
        id: netCheckTimer
        interval: 5000
        repeat: false
        onTriggered: netCheckProc.running = true
    }

    // Finder / App launcher
    Tui.TuiButton {
        text: "󰍉"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "finder"
        activeColor: Theme.accent
        onClicked: PanelState.openRight("finder")

        Layout.alignment: Qt.AlignVCenter
    }

    // Notifications
    Tui.TuiButton {
        text: "󰂚"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "notifications"
        activeColor: Theme.nord13
        onClicked: PanelState.openRight("notifications")

        // Show dot indicator when notifications exist
        Text {
            visible: NotificationManager.count > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -2
            anchors.rightMargin: -2
            text: Theme.dotSmall
            color: Theme.warning
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }

        Layout.alignment: Qt.AlignVCenter
    }


    // Keybind cheat-sheet
    Tui.TuiButton {
        text: "⌨"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "keybinds"
        activeColor: Theme.nord15
        onClicked: PanelState.openRight("keybinds")

        Layout.alignment: Qt.AlignVCenter
    }

    // Volume control
    Tui.TuiButton {
        text: "󰕾"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "volume"
        activeColor: Theme.nord7
        onClicked: PanelState.openRight("volume")

        Layout.alignment: Qt.AlignVCenter
    }

    // Brightness
    Tui.TuiButton {
        text: "󰃟"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "brightness"
        activeColor: Theme.nord13
        onClicked: PanelState.openRight("brightness")

        Layout.alignment: Qt.AlignVCenter
    }

    // Bluetooth
    Tui.TuiButton {
        text: "󰂯"
        fontSize: Theme.fontSize
        active: PanelState.rightPanelContext === "bluetooth"
        activeColor: Theme.nord9
        onClicked: PanelState.openRight("bluetooth")

        Layout.alignment: Qt.AlignVCenter
    }

    // Network (WiFi or Ethernet)
    Tui.TuiButton {
        text: root.hasEthernet ? "󰈀" : "󰖩"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "wifi"
        activeColor: Theme.nord8
        onClicked: PanelState.openRight("wifi")

        Layout.alignment: Qt.AlignVCenter
    }

    // Power menu
    Tui.TuiButton {
        text: "⏻"
        fontSize: Theme.fontSizeIcon
        active: PanelState.rightPanelContext === "power"
        activeColor: Theme.error
        onClicked: PanelState.openRight("power")

        Layout.alignment: Qt.AlignVCenter
    }
}
