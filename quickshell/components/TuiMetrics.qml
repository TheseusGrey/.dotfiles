pragma Singleton

import QtQuick
import Quickshell
import qs.services

// TuiMetrics — the monospace cell grid.
// Every chrome element that draws text-derived shapes (progress bars, rules,
// rails, list rows) must measure from here so joints line up across the
// header, left rail, right strip, and footer.
//
// cellWidth: width of one character cell at Theme.fontSize in Theme.fontFamily.
// lineHeight: height of one text line at Theme.fontSize.
// colsFor(width): how many character cells fit in a pixel width.
// rowsFor(height): how many text lines fit in a pixel height.

Singleton {
    id: metrics

    readonly property real cellWidth: tm.advanceWidth
    readonly property real lineHeight: tm.height

    function colsFor(width) {
        return Math.max(0, Math.floor(width / metrics.cellWidth));
    }

    function rowsFor(height) {
        return Math.max(0, Math.floor(height / metrics.lineHeight));
    }

    TextMetrics {
        id: tm
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        text: "M"
    }
}