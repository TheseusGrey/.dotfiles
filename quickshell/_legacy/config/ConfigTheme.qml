pragma Singleton
import QtQuick

QtObject {
    // Border
    readonly property int borderThickness: 24
    readonly property int borderRounding: 25
    readonly property color surface1: "#313244"
    readonly property color surface2: "#252638"

    // Dimensions
    readonly property int navPanelSize: 48
    readonly property int sidePanelCollapsedSize: 60
    readonly property int sidePanelExpandedSize: 200

    // Animations
    readonly property int animDuration: 200

    // Typography
    readonly property color fontColor: "#DDDDDD"
    readonly property int fontSize: 20
    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"
}
