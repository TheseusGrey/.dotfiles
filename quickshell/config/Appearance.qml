pragma Singleton


import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property int activeSize: 40
    readonly property int inactiveSize: 12

    readonly property int fontSize: 14
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property string surfaceColor: "#"
}
