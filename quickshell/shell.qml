import QtQuick
import Quickshell

ShellRoot {
    // Screen border overlay
    BorderOverlay {}

    // 1. Top Panel
    PanelWindow {
        id: topPanel
        anchors.top: true
        anchors.left: true
        anchors.right: true
        height: ConfigTheme.topPanelHeight
        exclusionMode: PanelWindow.ExclusionMode.Exclusive

        Rectangle {
            anchors.fill: parent
            color: ConfigTheme.bgMedium
            border.color: ConfigTheme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Top Panel (Waybar Skeleton)"
                color: ConfigTheme.text
            }
        }
    }

    // 2. Left Panel
    PanelWindow {
        id: leftPanel
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        
        width: leftHoverArea.containsMouse ? ConfigTheme.sidePanelExpandedWidth : ConfigTheme.sidePanelCollapsedWidth
        exclusionMode: PanelWindow.ExclusionMode.None

        Behavior on width {
            NumberAnimation { 
                duration: ConfigTheme.animDuration
                easing.type: Easing.InOutQuad 
            }
        }

        Rectangle {
            anchors.fill: parent
            color: ConfigTheme.bgDark
            border.color: ConfigTheme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: leftHoverArea.containsMouse ? "Left Expanded" : "L"
                color: ConfigTheme.text
                rotation: leftHoverArea.containsMouse ? 0 : -90
            }

            MouseArea {
                id: leftHoverArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    // 3. Right Panel
    PanelWindow {
        id: rightPanel
        anchors.top: true
        anchors.bottom: true
        anchors.right: true
        
        width: rightHoverArea.containsMouse ? ConfigTheme.sidePanelExpandedWidth : ConfigTheme.sidePanelCollapsedWidth
        exclusionMode: PanelWindow.ExclusionMode.None

        Behavior on width {
            NumberAnimation { 
                duration: ConfigTheme.animDuration
                easing.type: Easing.InOutQuad 
            }
        }

        Rectangle {
            anchors.fill: parent
            color: ConfigTheme.bgDark
            border.color: ConfigTheme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: rightHoverArea.containsMouse ? "Right Expanded" : "R"
                color: ConfigTheme.text
                rotation: rightHoverArea.containsMouse ? 0 : 90
            }

            MouseArea {
                id: rightHoverArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }
}
