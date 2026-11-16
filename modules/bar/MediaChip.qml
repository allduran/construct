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

    // Anchos naturales, independientes de lo que el layout le dé (así la barra puede
    // decidir "compact" con ellos sin bucles). Texto: como mucho 220 px.
    readonly property string title: (p?.trackTitle ?? "").trim()
    readonly property string artist: (p?.trackArtist ?? "").trim()
    readonly property real chrome: padding * 2 + 32 + 12 * 2 + playGlyph.implicitWidth   // todo salvo el texto
    readonly property real minWidth: chrome                                              // eq + ▶
    readonly property real fullWidth: chrome + Math.min(fullMetrics.advanceWidth, 220)
    readonly property real compactWidth: chrome + Math.min(titleMetrics.advanceWidth, 220)
    implicitWidth: compact ? compactWidth : fullWidth

    TextMetrics {
        id: fullMetrics
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsBase
        text: chip.title + (chip.title && chip.artist ? " — " + chip.artist : "")
    }
    TextMetrics {
        id: titleMetrics
        font: fullMetrics.font
        text: chip.title || "SIN DATOS"
    }

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
            // Cede al ancho que el layout le da al chip (el título se elide)
            width: Math.max(0, Math.min(implicitWidth, 220, chip.width - chip.chrome))
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: (t || "SIN DATOS").replace(/</g, "&lt;") + (t && a && !chip.compact ? ` <font color="${Theme.textDim}">— ${a.replace(/</g, "&lt;")}</font>` : "")
            color: t ? Theme.text : Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsBase
        }

        Text {
            id: playGlyph
            anchors.verticalCenter: parent.verticalCenter
            text: chip.playing ? "▶" : "❚❚"
            color: Theme.accent
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsXs
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
