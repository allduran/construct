import Quickshell
import QtQuick
import qs.common
import qs.components
import qs.services

// ♪ ecualizador + título — artista. Clic: panel · Central: play/pausa · Rueda: pista.
CutPanel {
    id: chip
    readonly property var p: Media.player
    readonly property bool playing: p?.isPlaying ?? false

    // Barra estrecha: solo título, sin artista (la ventana activa tiene prioridad)
    property bool compact: false

    visible: Media.active
    padding: 14
    cutTopRight: 0
    scanlines: false
    color: ShellState.mediaOpen ? Qt.alpha(Theme.accent, 0.12) : Theme.surface
    borderColor: ShellState.mediaOpen ? Theme.accent : Theme.accentFaint

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Mini ecualizador a saltos (~7 fps, tipo VU-meter digital): se mueve solo si suena
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 5 * 4 + 4 * 3
            height: 18

            Row {
                anchors.bottom: parent.bottom
                spacing: 3
                Repeater {
                    id: eq
                    model: 5
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: 4
                        height: 5
                        color: Theme.accent
                    }
                }
            }

            Timer {
                interval: 140
                repeat: true
                running: chip.playing && chip.visible && !Theme.gameMode && (chip.QsWindow.window?.visible ?? true)
                onTriggered: {
                    for (let i = 0; i < eq.count; i++)
                        eq.itemAt(i).height = 5 + Math.round(Math.random() * 13);
                }
                // Al pararse (pausa, modo juego), las barras vuelven a reposo
                onRunningChanged: if (!running) {
                    for (let i = 0; i < eq.count; i++)
                        eq.itemAt(i).height = 5;
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            readonly property string t: (chip.p?.trackTitle ?? "").trim()
            readonly property string a: (chip.p?.trackArtist ?? "").trim()
            width: Math.min(implicitWidth, 220)
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: (t || "SIN SEÑAL").replace(/</g, "&lt;") + (t && a && !chip.compact ? ` <font color="${Theme.textDim}">— ${a.replace(/</g, "&lt;")}</font>` : "")
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsBase
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.playing ? "▶" : "❚❚"
            color: Theme.accent
            font.family: Theme.fontMono
            font.pixelSize: 11
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            if (e.button === Qt.MiddleButton) {
                Media.toggle();
                return;
            }
            const open = !ShellState.mediaOpen;
            ShellState.mediaX = chip.mapToItem(null, 0, 0).x + 16;   // +16: margen izquierdo de la barra
            ShellState.closeAll();
            ShellState.mediaOpen = open;
        }
        onWheel: w => w.angleDelta.y > 0 ? Media.previous() : Media.next()
    }
}
