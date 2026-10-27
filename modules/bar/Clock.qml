import Quickshell
import QtQuick
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
        precision: SystemClock.Seconds
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Hora + segundos pegados, alineados por la línea base
        Row {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: time
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.accentFg
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fsXl
            }
            Text {
                anchors.baseline: time.baseline
                text: Qt.formatTime(clock.date, ":ss")
                color: Theme.accentFg
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fsMd
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
