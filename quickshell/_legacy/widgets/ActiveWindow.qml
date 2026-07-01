import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.theme

Text {
    text: Hyprland.focusedClient?.title ?? ""
    color: Theme.fgDim
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    elide: Text.ElideRight
    maximumLineCount: 1
    width: Math.min(implicitWidth, 300)
}
