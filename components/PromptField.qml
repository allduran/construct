import QtQuick
import qs.common

// Buscador tipo prompt: "> " + placeholder + cursor de bloque (+ pista a la derecha).
// Las teclas se gestionan fuera: onKeyPressed: e => { …; e.accepted = true }
CutPanel {
    id: root

    property string placeholder: ""
    property string hint: ""          // p. ej. "ESC"
    property alias text: input.text
    readonly property alias input: input
    signal keyPressed(var e)

    height: 64
    padding: 22
    cutTopRight: Theme.cutLg
    cutBottomLeft: Theme.cutLg
    scanlines: false
    color: Qt.alpha(Theme.bg, 0.94)
    borderColor: Theme.accent

    Row {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: 14

        Text {
            id: gt
            anchors.verticalCenter: parent.verticalCenter
            text: ">"
            color: Theme.accent
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsLg + 4
        }

        TextInput {
            id: input
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - gt.width - (hintText.visible ? hintText.width + parent.spacing : 0) - parent.spacing
            color: Theme.textBright
            selectionColor: Theme.accentDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsLg + 4
            clip: true

            Keys.onPressed: e => root.keyPressed(e)

            // Cursor de bloque parpadeante
            cursorDelegate: Rectangle {
                id: caret
                width: 12
                color: Theme.accent
                Timer {
                    interval: 530
                    running: input.activeFocus
                    repeat: true
                    onTriggered: caret.opacity = caret.opacity > 0 ? 0 : 1
                }
            }

            // Texto de ayuda cuando está vacío
            Text {
                visible: !input.text
                anchors.verticalCenter: parent.verticalCenter
                x: 20
                text: root.placeholder
                color: Theme.textDim
                font: input.font
            }
        }

        Text {
            id: hintText
            visible: root.hint !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.hint
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
            font.letterSpacing: 2
        }
    }
}
