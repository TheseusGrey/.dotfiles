import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.services
import qs.components as Tui

// Lock Screen — full session lock using ext-session-lock-v1 protocol.
// TUI aesthetic: centered box with clock, date, password input.
// Uses PamContext for authentication.
//
// Activated via: qs ipc call shell lock
//
// Visual when locked:
//   ╭──────────────────────────╮
//   │        14:32              │
//   │    Wed, Jul 01 2026       │
//   │                           │
//   │  ╭─ password ──────────╮ │
//   │  │ > ●●●●●●●           │ │
//   │  ╰─────────────────────╯ │
//   │                           │
//   │    enter to unlock        │
//   ╰──────────────────────────╯
//
// WARNING: If this component is destroyed while locked=true,
// the compositor will keep the screen locked with a solid color.
// Always set locked=false before exiting.

WlSessionLock {
    id: lock

    property bool lockRequested: false

    // ─── PAM Authentication ──────────────────────────────────────────
    PamContext {
        id: pam
        config: "login"

        onCompleted: function(result) {
            if (result === PamResult.Success) {
                lock.locked = false;
                lock.lockRequested = false;
            } else {
                // Auth failed — shake animation + restart
                shakeAnim.start();
                errorText.visible = true;
                errorHideTimer.start();
                pam.start();
            }
        }
    }

    Timer {
        id: errorHideTimer
        interval: 3000
        onTriggered: errorText.visible = false
    }

    // ─── Lock activation (called from PanelState/IPC) ────────────────
    function activate() {
        lock.lockRequested = true;
        lock.locked = true;
        pam.start();
    }

    // Listen to PanelState for lock requests
    Connections {
        target: PanelState
        function onLockRequested() {
            lock.activate();
        }
    }

    // ─── Lock Surface (instantiated per screen) ──────────────────────
    WlSessionLockSurface {
        id: surface
        color: Theme.bg

        // ─── Background fill ─────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: Theme.bg
        }

        // ─── Centered lock box ───────────────────────────────────────
        Item {
            id: lockBox
            anchors.centerIn: parent
            width: 320
            height: lockLayout.implicitHeight + 48

            // Use Translate transform so shake doesn't conflict with anchors
            transform: Translate { id: shakeTranslate; x: 0 }

            // Shake animation on auth failure
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shakeTranslate; property: "x"; to: 10; duration: 50 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 6; duration: 50 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: -6; duration: 50 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 50 }
            }

            ColumnLayout {
                id: lockLayout
                anchors.centerIn: parent
                width: parent.width
                spacing: 8

                // ─── Top border ──────────────────────────────────────
                Text {
                    Layout.fillWidth: true
                    text: Theme.boxTopLeft + Theme.boxHorizontal.repeat(36) + Theme.boxTopRight
                    color: Theme.border
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    horizontalAlignment: Text.AlignHCenter
                }

                // ─── Clock ───────────────────────────────────────────
                SystemClock {
                    id: lockClock
                    precision: SystemClock.Minutes
                }

                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(lockClock.date, "HH:mm")
                    color: Theme.textBright
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                // ─── Date ────────────────────────────────────────────
                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(lockClock.date, "dddd, MMMM d yyyy")
                    color: Theme.accentSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    horizontalAlignment: Text.AlignHCenter
                }

                // ─── Spacer ──────────────────────────────────────────
                Item { Layout.preferredHeight: 16 }

                // ─── Password input box ──────────────────────────────
                Text {
                    Layout.fillWidth: true
                    text: "  " + Theme.boxTopLeft + Theme.boxHorizontal + " password " + Theme.boxHorizontal.repeat(22) + Theme.boxTopRight
                    color: Theme.border
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    spacing: 0

                    Text {
                        text: Theme.boxVertical + " > "
                        color: Theme.border
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    // Password field (masked with ● characters)
                    TextInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        color: Theme.textBright
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        focus: lock.locked

                        onAccepted: {
                            if (text.length > 0 && pam.responseRequired) {
                                pam.respond(text);
                                text = "";
                            }
                        }
                    }

                    Text {
                        text: " " + Theme.boxVertical
                        color: Theme.border
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "  " + Theme.boxBottomLeft + Theme.boxHorizontal.repeat(33) + Theme.boxBottomRight
                    color: Theme.border
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                // ─── Spacer ──────────────────────────────────────────
                Item { Layout.preferredHeight: 8 }

                // ─── Help text ───────────────────────────────────────
                Text {
                    id: errorText
                    Layout.fillWidth: true
                    visible: false
                    text: "authentication failed"
                    color: Theme.error
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "enter to unlock"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                }

                // ─── Bottom border ───────────────────────────────────
                Text {
                    Layout.fillWidth: true
                    text: Theme.boxBottomLeft + Theme.boxHorizontal.repeat(36) + Theme.boxBottomRight
                    color: Theme.border
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
