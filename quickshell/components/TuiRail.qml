import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// Vertical rail of TuiButton glyphs used for collapsed status strips
// (left rail / right icon strip). Renders one button per model entry,
// each snapped to a fixed cell width and centered.
// An optional vertical rule can be drawn on one edge.
//
// Usage:
//   TuiRail {
//       wallSide: "right"
//       model: ["v", "b", "n"]
//       onActivated: item => { ... }
//   }

Item {
    id: root

    // "none" | "left" | "right" | "both"
    property string wallSide: "none"
    property color wallColor: Theme.border
    property int spacing: Theme.itemSpacing
    property var model: []
    property color normalColor: Theme.textMuted
    property color activeColor: Theme.accent

    // item can be a string or an object ({ glyph, active })
    signal activated(var item)

    readonly property real cellW: Tui.TuiMetrics.cellWidth
    readonly property int visibleCount: {
        if (root.model === undefined || root.model === null) return 0;
        if (Array.isArray(root.model)) return root.model.length;
        return root.model.count !== undefined ? root.model.count : 0;
    }

    implicitWidth: Tui.TuiMetrics.cellWidth * 2
    implicitHeight: visibleCount > 0
        ? Tui.TuiMetrics.lineHeight * visibleCount + root.spacing * Math.max(0, visibleCount - 1)
        : 0

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: root.spacing

        Repeater {
            model: root.model

            Tui.TuiButton {
                required property var modelData
                readonly property string glyph: (typeof modelData === "string") ? modelData : (modelData.glyph ?? "")
                readonly property bool isActive: (typeof modelData === "object") ? !!modelData.active : false
                property var item: modelData

                text: glyph
                variant: "body"
                textAlign: Text.AlignHCenter
                normalColor: root.normalColor
                activeColor: root.activeColor
                active: isActive
                implicitHeight: Tui.TuiMetrics.lineHeight
                Layout.fillWidth: true
                onClicked: root.activated(modelData)
            }
        }
    }

    // ─── Vertical walls ──────────────────────────────────────────────
    Rectangle {
        visible: root.wallSide === "left" || root.wallSide === "both"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: root.wallColor
    }

    Rectangle {
        visible: root.wallSide === "right" || root.wallSide === "both"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: root.wallColor
    }
}