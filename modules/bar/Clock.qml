import Quickshell
import QtQuick
import QtQml
import qs.common
import qs.components

// Reloj: bloque sólido de acento con hora grande, segundos y fecha.
CutPanel {
    id: root
    cutTopRight: 0
    cutTopLeft: Theme.cut
    color: Theme.accent
    borderWidth: 0

    readonly property var es: Qt.locale("es_ES")

    // Reloj del sistema de Quickshell; solo emite cambios con la precisión pedida
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Hora (sin segundos: un fotograma por minuto, no por segundo)
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: time.width
            height: time.implicitHeight

            // Ancho fijo con el dígito más ancho de la fuente (proporcional)
            // para que el layout no cambie cada minuto
            Instantiator {
                id: digitsXl
                model: 10
                delegate: TextMetrics {
                    required property int index
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fsXl
                    text: String(index)
                }
            }
            TextMetrics {
                id: colonXl
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fsXl
                text: ":"
            }

            Text {
                id: time
                width: {
                    let m = 0;
                    for (let i = 0; i < digitsXl.count; i++)
                        m = Math.max(m, digitsXl.objectAt(i).advanceWidth);
                    return Math.ceil(4 * m + colonXl.advanceWidth) + 1;
                }
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.accentFg
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fsXl
            }
        }

        // Día y fecha en dos líneas
        Column {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                // "lun." → "LUN"
                text: clock.date.toLocaleString(root.es, "ddd").replace(".", "").toUpperCase()
                color: Theme.accentFg
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsXs
                font.weight: Font.DemiBold
                font.letterSpacing: 1.4
            }
            Text {
                text: Qt.formatDate(clock.date, "dd·MM·yy")
                color: Theme.accentFg
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsXs
                font.weight: Font.DemiBold
            }
        }
    }
}
