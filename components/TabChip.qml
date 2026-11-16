import QtQuick
import qs.common

// Pestaña con chaflán: etiqueta (+ contador opcional). Clic: signal clicked().
CutPanel {
    id: root

    property string label: ""
    property string count: ""         // vacío = sin contador
    property bool on: false
    signal clicked

    width: row.implicitWidth + 36
    height: 40
    padding: 0
    cutTopRight: Theme.cutTab
    scanlines: false
    color: on ? Theme.accent : Theme.surface
    borderColor: on ? Theme.accent : Theme.accentDim

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
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
            opacity: 0.7
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fsBase
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
