import QtQuick

// Texto con cifras tabulares emuladas: cada carácter va en su celda; las cifras
// comparten el ancho del dígito más ancho (el "0" en ChakraPetch) con la cifra
// centrada, el resto usa su ancho natural. Con longitud estable no se recrean delegados.
Item {
    id: root

    property string text
    property color color: "white"
    property alias font: metrics.font

    readonly property real digitWidth: Math.ceil(metrics.advanceWidth)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    TextMetrics {
        id: metrics
        text: "0"
    }

    Row {
        id: row

        Repeater {
            model: root.text.length

            delegate: Item {
                id: cell
                required property int index
                readonly property string ch: root.text.charAt(index)
                readonly property bool digit: ch >= "0" && ch <= "9"

                width: digit ? root.digitWidth : glyph.implicitWidth
                height: glyph.implicitHeight

                Text {
                    id: glyph
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.ch
                    color: root.color
                    font: root.font
                }
            }
        }
    }
}
