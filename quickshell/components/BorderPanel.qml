import QtQuick
import qs.theme

// Base component for hover-to-expand border panels.
// Set `edge` to "top", "bottom", "left", or "right".
// Put expanded content in the default property.
Item {
    id: root

    required property string edge
    property bool expanded: false
    property alias content: contentLoader.sourceComponent

    readonly property bool isVertical: edge === "left" || edge === "right"
    readonly property int collapsedSize: Theme.borderThickness
    readonly property int expandedSize: isVertical ? Theme.expandedPanelWidth : Theme.expandedBarHeight

    // Hover area that triggers expansion
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onContainsMouseChanged: {
            root.expanded = containsMouse;
        }
        // Allow clicks to pass through to content
        onPressed: (mouse) => mouse.accepted = false
        onReleased: (mouse) => mouse.accepted = false
    }

    // Collapsed border line
    Rectangle {
        id: borderLine
        color: Theme.border
        visible: !root.expanded

        anchors {
            top: root.edge === "top" || root.edge === "left" || root.edge === "right" ? parent.top : undefined
            bottom: root.edge === "bottom" || root.edge === "left" || root.edge === "right" ? parent.bottom : undefined
            left: root.edge === "left" || root.edge === "top" || root.edge === "bottom" ? parent.left : undefined
            right: root.edge === "right" || root.edge === "top" || root.edge === "bottom" ? parent.right : undefined
        }

        implicitWidth: root.isVertical ? root.collapsedSize : parent.width
        implicitHeight: root.isVertical ? parent.height : root.collapsedSize
    }

    // Expanded content
    Loader {
        id: contentLoader
        anchors.fill: parent
        active: root.expanded
        visible: root.expanded
    }
}
