import Quickshell
import QtQuick
import qs.common
import qs.components

// Calendario mensual (lunes primero). Flechas o rueda: cambiar de mes.
// Clic en el título: volver al mes actual.
CutPanel {
    id: cal
    padding: 14
    cutTopRight: 0
    cutBottomLeft: 12
    scanlines: false
    color: "transparent"
    borderColor: Theme.accentFaint

    readonly property var es: Qt.locale("es_ES")

    // Precisión de minutos: así "hoy" cambia solo a medianoche
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    property int offset: 0      // meses respecto al actual (−1 = el anterior)
    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    // Ancho de cada columna: el panel se reparte entre 7
    readonly property real cellW: (width - padding * 2) / 7

    // Semanas completas: días del mes anterior y siguiente para rellenar
    readonly property var cells: {
        const y = shown.getFullYear(), m = shown.getMonth();
        const start = (shown.getDay() + 6) % 7;            // getDay(): 0 = domingo → lunes = 0
        const daysInMonth = new Date(y, m + 1, 0).getDate();
        const total = Math.ceil((start + daysInMonth) / 7) * 7;
        const out = [];
        for (let i = 0; i < total; i++) {
            const d = new Date(y, m, i - start + 1);       // Date corrige solo días < 1 o > fin de mes
            out.push({
                n: d.getDate(),
                inMonth: d.getMonth() === m,
                isToday: d.toDateString() === today.toDateString(),
                weekend: i % 7 >= 5
            });
        }
        return out;
    }

    // Semana ISO 8601 (la que se usa en España)
    function isoWeek(d: date): int {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);            // jueves de esa semana
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
    }

    Column {
        width: cal.cellW * 7
        spacing: 8

        // ── Cabecera: mes, semana y flechas ──
        Item {
            width: parent.width
            height: 32

            Text {
                id: monthTitle
                anchors.verticalCenter: parent.verticalCenter
                text: cal.shown.toLocaleString(cal.es, "MMMM yyyy").toUpperCase()
                color: Theme.accent
                font.family: Theme.fontDisplay
                font.pixelSize: 13
                font.letterSpacing: Theme.tracking

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cal.offset = 0
                }
            }

            Text {
                anchors.left: monthTitle.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: cal.offset === 0
                text: "SEM " + cal.isoWeek(cal.today)
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsXs
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: [
                        {
                            label: "‹",
                            step: -1
                        },
                        {
                            label: "›",
                            step: 1
                        }
                    ]

                    delegate: CutPanel {
                        id: arrow
                        required property var modelData
                        width: 32
                        height: 32
                        padding: 0
                        cutTopRight: 8
                        scanlines: false
                        color: "transparent"
                        borderColor: Theme.accentDim

                        Text {
                            anchors.centerIn: parent
                            text: arrow.modelData.label
                            color: Theme.accent
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cal.offset += arrow.modelData.step
                        }
                    }
                }
            }
        }

        // ── Días de la semana ──
        Row {
            Repeater {
                model: ["L", "M", "X", "J", "V", "S", "D"]
                Text {
                    required property string modelData
                    width: cal.cellW
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsXs
                }
            }
        }

        // ── Cuadrícula ──
        Grid {
            columns: 7

            Repeater {
                model: cal.cells

                delegate: Item {
                    id: cell
                    required property var modelData
                    width: cal.cellW
                    height: 30

                    // Hoy: bloque sólido de acento
                    Rectangle {
                        anchors.centerIn: parent
                        width: 30
                        height: 26
                        visible: cell.modelData.isToday
                        color: Theme.accent
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.n
                        color: cell.modelData.isToday ? Theme.accentFg : !cell.modelData.inMonth ? Qt.alpha(Theme.textDim, 0.45) : cell.modelData.weekend ? Theme.textDim : Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                        font.weight: cell.modelData.isToday ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }

    // Rueda: mes anterior / siguiente
    WheelHandler {
        onWheel: e => cal.offset += e.angleDelta.y > 0 ? -1 : 1
    }
}
