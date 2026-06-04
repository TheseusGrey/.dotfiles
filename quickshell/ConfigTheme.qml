pragma Singleton
import QtQuick

QtObject {
    // Colors
    readonly property color bgDark: "#11111b"
    readonly property color bgMedium: "#1e1e2e"
    readonly property color border: "#313244"
    readonly property color text: "#cdd6f4"

    // Border
    readonly property int borderThickness: 10
    readonly property int borderRounding: 25
    readonly property color borderColor: "#313244"

    // Dimensions
    readonly property int topPanelHeight: 40
    readonly property int sidePanelCollapsedWidth: 60
    readonly property int sidePanelExpandedWidth: 200

    // Animations
    readonly property int animDuration: 200
}
