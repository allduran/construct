import QtQuick
import qs.common

// Pestaña con chaflán: etiqueta (+ contador opcional). Clic: signal clicked().
CutPanel {
    id: root

    property string label: ""
    property string count: ""         // vacío = sin contador
    property string prefix: ""        // número delante (atajo de teclado), vacío = ninguno
    property bool on: false
    signal clicked

    width: row.implicitWidth + 36
    height: Theme.tabHeight
    padding: 0
    cutTopRight: Theme.cutTab
    scanlines: false
    color: on ? Theme.accent : hv.hovered ? Qt.alpha(Theme.accent, 0.12) : Theme.surface
    borderColor: on ? Theme.accent : Theme.accentDim

    HoverHandler {
        id: hv
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            visible: root.prefix !== ""
            text: root.prefix
            color: root.on ? Theme.accentFg : Theme.accent
            opacity: 0.6
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fsBase
        }
        Text {
            text: root.label
            color: root.on ? Theme.accentFg : Theme.textDim
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fsBase
            font.letterSpacing: Theme.tracking
        }
        Text {
            visible: root.count !== ""
            text: root.count
            color: root.on ? Theme.accentFg : Theme.textDim
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fsSm
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
