import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common

// Ventana con foco: APP ▸ título █
Item {
    id: root

    // Ventana activa según el protocolo de Wayland (null si no hay ninguna)
    readonly property var win: ToplevelManager.activeToplevel

    // "org.kde.dolphin" → "DOLPHIN"
    readonly property string app: win?.appId ? win.appId.split(".").pop().toUpperCase() : "IDLE"
    readonly property string title: win?.title || "esperando instrucciones…"

    // Medios ciclos de parpadeo que quedan (par: termina encendido)
    property int blinks: 16
    onTitleChanged: blinks = 16

    Row {
        anchors.centerIn: parent
        spacing: 10

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: root.app
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsXs
            font.letterSpacing: 2
        }

        Text {
            id: sep
            anchors.verticalCenter: parent.verticalCenter
            text: "▸"
            color: Theme.accent
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
        }

        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            // Su ancho natural, pero nunca más que el hueco disponible
            width: Math.min(implicitWidth, root.width - label.width - sep.width - cursor.width - parent.spacing * 3)
            elide: Text.ElideRight
            text: root.title
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsMd
        }

        Rectangle {
            id: cursor
            anchors.verticalCenter: parent.verticalCenter
            width: 9
            height: 16
            color: Theme.accent

            // Parpadeo tipo terminal, solo unos ciclos tras cambiar el título;
            // luego queda fijo, como un prompt en reposo. Se usa opacity y no
            // visible para que el Row no recoloque nada al apagarse.
            Timer {
                interval: 530
                running: root.blinks > 0 && root.visible && !Theme.gameMode && (root.QsWindow.window?.visible ?? true)
                repeat: true
                onTriggered: {
                    cursor.opacity = cursor.opacity > 0 ? 0 : 1;
                    root.blinks--;
                }
                onRunningChanged: if (!running)
                    cursor.opacity = 1
            }
        }
    }
}
