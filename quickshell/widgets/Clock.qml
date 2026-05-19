import QtQuick
import qs.theme

Text {
    id: root

    property string timeStr: ""
    property string dateStr: ""

    text: timeStr + "  " + dateStr
    color: Theme.fg
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            root.timeStr = Qt.formatDateTime(now, "hh:mm");
            root.dateStr = Qt.formatDateTime(now, "ddd, MMM d");
        }
    }
}
