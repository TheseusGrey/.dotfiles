import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components as Tui

// TUI-style calendar — monospace month grid with prev/next navigation.
//
// Visual:
//   ◂ July 2026 ▸
//   Mo Tu We Th Fr Sa Su
//         1  2  3  4  5
//    6  7  8  9 10 11 12
//   13 14 15 16 17 18 19
//   20 21 22 23 24 25 26
//   27 28 29 30 31
//                    [●] ← today indicator
//
ColumnLayout {
    id: root
    spacing: 4

    // Current displayed month/year (not necessarily today's)
    property int displayMonth: clock.date.getMonth()  // 0-indexed
    property int displayYear: clock.date.getFullYear()

    // Today's date for highlighting
    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    readonly property int todayDay: clock.date.getDate()
    readonly property int todayMonth: clock.date.getMonth()
    readonly property int todayYear: clock.date.getFullYear()

    // Month navigation
    function prevMonth() {
        if (displayMonth === 0) {
            displayMonth = 11;
            displayYear--;
        } else {
            displayMonth--;
        }
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0;
            displayYear++;
        } else {
            displayMonth++;
        }
    }

    function goToToday() {
        displayMonth = todayMonth;
        displayYear = todayYear;
    }

    // Helpers
    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    function daysInMonth(month: int, year: int): int {
        return new Date(year, month + 1, 0).getDate();
    }

    // Day of week for 1st of month (0=Sun, convert to Mon-start: 0=Mon)
    function firstDayOffset(month: int, year: int): int {
        const dow = new Date(year, month, 1).getDay(); // 0=Sun
        return dow === 0 ? 6 : dow - 1; // Convert to Mon=0
    }

    // ─── Header: ◂ Month Year ▸ ───
    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Tui.TuiButton {
            text: "◂"
            onClicked: root.prevMonth()
        }

        Item { Layout.fillWidth: true }

        Tui.TuiText {
            text: `${root.monthNames[root.displayMonth]} ${root.displayYear}`
            textColor: Theme.textBright
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Item { Layout.fillWidth: true }

        Tui.TuiButton {
            text: "▸"
            onClicked: root.nextMonth()
        }
    }

    // ─── Day-of-week header ───
    Tui.TuiText {
        text: "Mo Tu We Th Fr Sa Su"
        textColor: Theme.textMuted
        font.pixelSize: Theme.fontSizeSmall
    }

    // ─── Day grid ───
    // Rendered as rows of formatted text for perfect monospace alignment
    Column {
        id: dayGrid
        spacing: 1

        readonly property int offset: root.firstDayOffset(root.displayMonth, root.displayYear)
        readonly property int totalDays: root.daysInMonth(root.displayMonth, root.displayYear)
        readonly property int totalCells: offset + totalDays
        readonly property int numRows: Math.ceil(totalCells / 7)

        Repeater {
            model: dayGrid.numRows

            Text {
                required property int index
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                textFormat: Text.RichText

                text: {
                    let row = "";
                    for (let col = 0; col < 7; col++) {
                        const cellIndex = index * 7 + col;
                        const dayNum = cellIndex - dayGrid.offset + 1;

                        if (cellIndex < dayGrid.offset || dayNum > dayGrid.totalDays) {
                            // Empty cell
                            row += "   ";
                        } else {
                            const isToday = (dayNum === root.todayDay
                                          && root.displayMonth === root.todayMonth
                                          && root.displayYear === root.todayYear);
                            const isWeekend = (col >= 5); // Sat/Sun

                            const padded = dayNum < 10 ? ` ${dayNum}` : `${dayNum}`;

                            if (isToday) {
                                row += `<span style="color:${Theme.accent};font-weight:bold">${padded}</span> `;
                            } else if (isWeekend) {
                                row += `<span style="color:${Theme.textMuted}">${padded}</span> `;
                            } else {
                                row += `<span style="color:${Theme.textPrimary}">${padded}</span> `;
                            }
                        }
                    }
                    return row;
                }
            }
        }
    }

    // ─── Today shortcut (shown if not viewing current month) ───
    Tui.TuiButton {
        visible: root.displayMonth !== root.todayMonth || root.displayYear !== root.todayYear
        text: "● today"
        onClicked: root.goToToday()
        Layout.alignment: Qt.AlignRight
    }
}
