import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components as Tui
import qs.widgets as Widgets

// Floating date popup — drops down from below the top bar, centered.
// The window spans the full screen on the Overlay layer, but its input region
// (mask) is a single narrow column centered under the date+time that reaches
// from the top of the screen down through the popup. That one column is the
// continuous hover zone covering the clock trigger + the gap + the popup, so
// hover never races across surfaces — the popup stays open until the pointer
// leaves the whole column. Clicks outside the column pass through to the
// desktop, and clicks inside (calendar nav, "today") act normally without
// stealing focus or closing the popup.
// Shows a compact calendar plus a footer row of date info
// (day-of-year / ISO week / UTC offset).
PanelWindow {
    id: root

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    readonly property int gapHeight: 12
    readonly property int popupWidth: 420
    readonly property int popupHeight: 300

    // The hover column spans from the screen top (over the clock) down through
    // the popup, and is centered under the date+time.
    readonly property int colTop: 0
    readonly property int colHeight: Theme.topPanelHeight + gapHeight + popupHeight

    exclusionMode: ExclusionMode.Ignore
    visible: PanelState.datePopupVisible
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-date"

    // Input region: only the centered hover column receives pointer events, so
    // the rest of the top bar / desktop is never blocked. The column spans the
    // clock trigger + the gap + the popup, forming one continuous hover zone.
    mask: Region {
        item: hitZone
    }
    Item {
        id: hitZone
        x: (root.width - root.popupWidth) / 2
        y: root.colTop
        width: root.popupWidth
        height: root.colHeight
    }

    Timer {
        id: closeTimer
        interval: 250
        repeat: false
        onTriggered: PanelState.closeDatePopup()
    }

    // ─── Shell frame (same chrome as panels/rails) ──────────────────
    Tui.TuiPanel {
        id: frame
        anchors.horizontalCenter: parent.horizontalCenter
        y: (root.visible ? 0 : -16) + Theme.topPanelHeight + root.gapHeight
        width: root.popupWidth
        height: root.popupHeight
        opacity: root.visible ? 1 : 0

        Behavior on y {
            NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth + Theme.panelPadding
            spacing: Theme.itemSpacing

            // ─── Header: today's long date ────────────────────────────
            SystemClock {
                id: clock
                precision: SystemClock.Hours
            }

            Tui.TuiText {
                text: Qt.formatDateTime(clock.date, "dddd, MMMM d yyyy")
                textColor: Theme.titleColor
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // ─── Calendar grid ────────────────────────────────────────
            Widgets.Calendar {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }

            Tui.TuiRule { Layout.fillWidth: true }

            // ─── Info footer: day-of-year / ISO week / UTC offset ─────
            RowLayout {
                Layout.fillWidth: true
                spacing: Tui.TuiMetrics.cellWidth * 0.5

                Tui.TuiText {
                    text: "doy"
                    textColor: Theme.textMuted
                    variant: "small"
                }

                Tui.TuiText {
                    text: root.dayOfYear.toString()
                    textColor: Theme.textPrimary
                    variant: "small"
                }

                Item { Layout.fillWidth: true }

                Tui.TuiText {
                    text: "week"
                    textColor: Theme.textMuted
                    variant: "small"
                }

                Tui.TuiText {
                    text: root.isoWeek.toString()
                    textColor: Theme.textPrimary
                    variant: "small"
                }

                Item { Layout.fillWidth: true }

                Tui.TuiText {
                    text: "utc"
                    textColor: Theme.textMuted
                    variant: "small"
                }

                Tui.TuiText {
                    text: root.tzAbbr
                    textColor: Theme.textPrimary
                    variant: "small"
                }
            }
        }
    }

    // Hover sensor, laid over the whole input column (topmost) so it stays
    // "entered" even when the pointer is over the popup's own buttons (which
    // would otherwise steal hover from a sensor placed underneath). It accepts
    // no buttons, so clicks pass through to the calendar controls below; it
    // only tracks enter/exit of the continuous clock+gap+popup hover zone.
    MouseArea {
        id: sensor
        x: (root.width - root.popupWidth) / 2
        y: root.colTop
        width: root.popupWidth
        height: root.colHeight
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: closeTimer.stop()
        onExited: closeTimer.start()
    }

    // ─── Derived date info ───────────────────────────────────────────
    readonly property int dayOfYear: {
        const start = new Date(clock.date.getFullYear(), 0, 0);
        const diff = clock.date - start + (start.getTimezoneOffset() - clock.date.getTimezoneOffset()) * 60000;
        return Math.floor(diff / 86400000);
    }

    readonly property int isoWeek: {
        const d = new Date(Date.UTC(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate()));
        const dayNum = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - dayNum);
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
    }

    // Expanded "UTC±HH:MM" offset label (no Intl in the QML JS runtime).
    readonly property string tzAbbr: {
        const offsetMin = -clock.date.getTimezoneOffset();
        const sign = offsetMin >= 0 ? "+" : "−";
        const abs = Math.abs(offsetMin);
        const hh = Math.floor(abs / 60);
        const mm = abs % 60;
        return "UTC" + sign + String(hh).padStart(2, "0") + ":" + String(mm).padStart(2, "0");
    }
}
