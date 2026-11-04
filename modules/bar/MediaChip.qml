import QtQuick
import qs.common
import qs.components
import qs.services

// ♪ ecualizador + título — artista. Clic: panel · Central: play/pausa · Rueda: pista.
CutPanel {
    id: chip
    readonly property var p: Media.player
    readonly property bool playing: p?.isPlaying ?? false

    visible: Media.active
    padding: 14
    cutTopRight: 0
    scanlines: false
    color: ShellState.mediaOpen ? Qt.alpha(Theme.accent, 0.12) : Theme.surface
    borderColor: ShellState.mediaOpen ? Theme.accent : Theme.accentFaint

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Mini ecualizador: se mueve solo si suena
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 5 * 4 + 4 * 3
            height: 18

            Row {
                anchors.bottom: parent.bottom
                spacing: 3
                Repeater {
                    model: [0.7, 0.5, 0.9, 0.6, 0.8]
                    Rectangle {
                        id: bar
                        required property real modelData
                        anchors.bottom: parent.bottom
                        width: 4
                        height: 5
                        color: Theme.accent

                        SequentialAnimation on height {
                            running: chip.playing && chip.visible
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 18
                                duration: bar.modelData * 500
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 5
                                duration: bar.modelData * 500
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 300)
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: (chip.p?.trackTitle ?? "").replace(/</g, "&lt;") + (chip.p?.trackArtist ? ` <font color="${Theme.textDim}">— ${chip.p.trackArtist.replace(/</g, "&lt;")}</font>` : "")
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: 13
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.playing ? "▶" : "❚❚"
            color: Theme.accent
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
