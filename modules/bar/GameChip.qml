import QtQuick
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// ◆ JUEGO — aviso de HUD junto al reloj. Clic: salir del modo juego.
CutPanel {
    id: chip
    visible: Theme.gameMode
    padding: 0
    cutTopRight: 0
    cutTopLeft: Theme.cut
    scanlines: false
    color: Theme.yellow
    borderWidth: 0
    implicitWidth: row.implicitWidth + 16

    readonly property color ink: Theme.bg

    // Entrada: parpadeo + glitch del texto (una vez; luego todo queda quieto)
    onVisibleChanged: if (visible) {
        enter.restart();
        title.glitch();
    }
    SequentialAnimation {
        id: enter
        PropertyAction {
            target: chip
            property: "opacity"
            value: 0.2
        }
        PauseAnimation {
            duration: 50
        }
        PropertyAction {
            target: chip
            property: "opacity"
            value: 1
        }
        PauseAnimation {
            duration: 40
        }
        PropertyAction {
            target: chip
            property: "opacity"
            value: 0.4
        }
        PauseAnimation {
            duration: 40
        }
        PropertyAction {
            target: chip
            property: "opacity"
            value: 1
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.cut - 2
        spacing: 10

        // Mando
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 16

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: chip.ink
            }
            // Cruceta
            Rectangle {
                x: 5
                y: 6.5
                width: 7
                height: 3
                color: Theme.yellow
            }
            Rectangle {
                x: 7
                y: 4.5
                width: 3
                height: 7
                color: Theme.yellow
            }
            // Botones
            Rectangle {
                x: 16
                y: 4
                width: 3
                height: 3
                radius: 1.5
                color: Theme.yellow
            }
            Rectangle {
                x: 19.5
                y: 8
                width: 3
                height: 3
                radius: 1.5
                color: Theme.yellow
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: GameMode.set(false)
    }
}
