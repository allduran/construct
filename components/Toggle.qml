import QtQuick
import QtQuick.Layouts
import qs.common

// Interruptor: bloque que se rellena de acento al activarse.
CutPanel {
    id: t
    required property string label
    property string sub: ""
    required property bool on
    signal toggled

    Layout.fillWidth: true
    implicitHeight: 64
    padding: 14
    cutTopRight: 12
    scanlines: false
    color: on ? Theme.accent : "transparent"
    borderColor: on ? Theme.accent : Theme.accentDim
    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: 3
        Text {
            text: t.label
            color: t.on ? Theme.accentFg : Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: 13
            font.letterSpacing: Theme.tracking
        }
        Text {
            visible: t.sub !== ""
            width: parent.width
            elide: Text.ElideRight
            text: t.sub
            color: t.on ? Qt.alpha(Theme.accentFg, 0.75) : Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsXs
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: t.toggled()
    }
}
