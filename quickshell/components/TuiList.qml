import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components as Tui

// TuiList — a tree-list container for the context panel.
// Renders a column of TuiMenuItem rows; supports scrolling.
//
// Usage:
//   TuiList {
//       TuiMenuItem { marker: ">"; text: "File" }
//       TuiMenuItem { indent: 1; text: "Rename" }
//   }

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column
        width: root.width
        spacing: 0
    }

    // Default property so callers can add TuiMenuItems directly.
    default property alias content: column.data
}