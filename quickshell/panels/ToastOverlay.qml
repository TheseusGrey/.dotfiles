import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components as Tui

// ToastOverlay — transient theme/apply results. In-shell so it still works
// when no desktop notification daemon is available, and click-through so it
// never steals focus from an open panel.
PanelWindow {
    id: root

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-toast"

    mask: Region {
        item: emptyMask
    }
    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    property string title: ""
    property string body: ""
    property bool isError: false

    Connections {
        target: PanelState
        function onToastRequested(title, body, error) {
            root.show(title, body, error);
        }
    }

    function show(title, body, error) {
        root.title = title || "";
        root.body = body || "";
        root.isError = !!error;
        toastBox.opacity = 1;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: root.isError ? 8000 : 4000
        onTriggered: toastBox.opacity = 0
    }

    Item {
        id: toastBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        width: Math.min(toastItem.implicitWidth, 560)
        height: toastItem.implicitHeight
        opacity: 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Tui.TuiToast {
            id: toastItem
            anchors.left: parent.left
            anchors.right: parent.right
            text: root.title
            subText: root.body
            borderColor: root.isError ? Theme.error : Theme.border
            textColor: root.isError ? Theme.error : Theme.textPrimary
            subTextColor: Theme.textMuted
        }
    }
}
