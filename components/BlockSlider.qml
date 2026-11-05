import QtQuick
import QtQuick.Layouts
import qs.common

// Slider de bloques: clic, arrastre o rueda. value 0–1.
Column {
    id: s
    required property string label
    required property real value
    property color barColor: Theme.accent
    property int blocks: 20
    property string valueText: Math.round(value * 100) + "%"
    signal moved(real v)

    Layout.fillWidth: true
    spacing: 6

    Item {
        width: parent.width
        height: lbl.implicitHeight
        Text {
            id: lbl
            text: s.label
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
            font.letterSpacing: 1.6
        }
        Text {
            anchors.right: parent.right
            text: s.valueText
            color: Theme.textBright
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
        }
    }

    Item {
        width: parent.width
        height: 18

        Row {
            anchors.fill: parent
            spacing: 3
            Repeater {
                model: s.blocks
                Rectangle {
                    required property int index
                    width: (parent.width - (s.blocks - 1) * 3) / s.blocks
                    height: 18
                    color: index < Math.round(s.value * s.blocks) ? s.barColor : Theme.track
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function pick(x: real) {
                s.moved(Math.max(0, Math.min(1, x / width)));
            }
            onPressed: e => pick(e.x)
            onPositionChanged: e => {
                if (pressed)
                    pick(e.x);
            }
            onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
