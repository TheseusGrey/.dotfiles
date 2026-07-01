import QtQuick
import QtQuick.Layouts
import qs.services

// Dot indicator row (pagination / workspace state).
// Renders ● for active and ○ for inactive positions.
//
// Usage:
//   TuiDots {
//       count: 10
//       activeIndices: [0, 3, 5]   // which dots are filled
//       currentIndex: 3            // highlighted with accent color
//   }

RowLayout {
    id: root

    property int count: 5
    property var activeIndices: []   // which dots show as filled (●)
    property int currentIndex: -1    // the "focused" dot (gets accent color)
    property color activeColor: Theme.textPrimary
    property color currentColor: Theme.accent
    property color inactiveColor: Theme.textMuted

    spacing: 2

    Repeater {
        model: root.count

        Text {
            required property int index

            readonly property bool isActive: root.activeIndices.indexOf(index) !== -1
            readonly property bool isCurrent: index === root.currentIndex

            text: isActive || isCurrent ? Theme.dotFilled : Theme.dotEmpty
            color: isCurrent ? root.currentColor : isActive ? root.activeColor : root.inactiveColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter

            Layout.alignment: Qt.AlignVCenter
        }
    }
}
