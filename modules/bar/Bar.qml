import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components

// Barra superior: una por pantalla (la crea un Variants en shell.qml).
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "construct-bar"   // casa con la layer rule de hypr/shell.lua
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 12
        left: 16
        right: 16
    }
    implicitHeight: Theme.barHeight
    color: "transparent"

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Theme.gap

        // Reparto del ancho: los bloques fijos nunca ceden; la música es lo primero que
        // se encoge y, si aun así no cabe, la ventana activa. Todo lo que entra en estas
        // cuentas son anchos naturales de bloques fijos: nada depende del ancho de la música.
        readonly property int blocks: 4 + (mediaChip.visible ? 1 : 0) + (recChip.visible ? 1 : 0)
            + (trayPanel.visible ? 1 : 0) + (gameChip.visible ? 1 : 0)
        // (Qt redondea hacia arriba el ancho de cada bloque: se cuenta igual para no pasarse)
        readonly property real fixedWidth: Math.ceil(logoPanel.implicitWidth) + Math.ceil(metersPanel.implicitWidth) + Math.ceil(clockBlock.implicitWidth)
            + (trayPanel.visible ? Math.ceil(trayPanel.implicitWidth) : 0) + (recChip.visible ? Math.ceil(recChip.implicitWidth) : 0)
            + (gameChip.visible ? Math.ceil(gameChip.implicitWidth) : 0) + (blocks - 1) * Theme.gap
        // Hueco para ventana activa + música
        readonly property real shared: row.width - fixedWidth
        readonly property real windowWish: 260                  // ancho que se le reserva a la ventana activa
        readonly property real windowMin: 180                   // APP ▸ + unas letras + cursor
        readonly property real mediaMin: mediaChip.visible ? mediaChip.minWidth : 0

        // ── Izquierda: logo + espacios de trabajo ──
        CutPanel {
            id: logoPanel
            Layout.fillHeight: true
            Layout.minimumWidth: implicitWidth
            cutTopRight: Theme.cut
            borderColor: Theme.accentDim

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                GlitchText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CNSTRCT//"
                    color: Theme.accent
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fsLg
                    font.letterSpacing: Theme.tracking
                }

                Workspaces {
                    anchors.verticalCenter: parent.verticalCenter
                    monitor: Hyprland.monitorFor(bar.screen)
                }
            }
        }

        // ── Centro: ventana activa (ocupa el hueco libre) ──
        CutPanel {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: 1     // no pide ancho por su contenido: solo el hueco libre
            // Mínimo 180; solo baja si ni con la música al mínimo cabe
            Layout.minimumWidth: row.shared - row.windowMin >= row.mediaMin ? row.windowMin : Math.max(60, row.shared - row.mediaMin)
            clip: true                   // nunca pinta fuera de su chaflán
            cutTopRight: 0
            borderColor: Theme.accentFaint

            ActiveWindow {
                anchors.fill: parent
            }
        }

        // ── Música y grabación ──
        MediaChip {
            id: mediaChip
            Layout.fillHeight: true
            Layout.minimumWidth: minWidth                     // eq + ▶: lo último que queda
            // Pide su ancho natural, pero cede lo que haga falta (hasta eq + ▶) para que la
            // ventana activa conserve sus 260 (solo baja de ahí con la música ya al mínimo); el layout no reparte bien el recorte por sí solo
            Layout.preferredWidth: Math.max(minWidth, Math.min(implicitWidth, Math.floor(row.shared - row.windowWish)))
            // Sin artista cuando el hueco real (con la ventana activa a 260) no da para todo
            compact: row.shared - row.windowWish < fullWidth
        }
        RecChip {
            id: recChip
            Layout.fillHeight: true
            Layout.minimumWidth: implicitWidth
        }

        // ── Derecha: medidores ──
        CutPanel {
            id: metersPanel
            Layout.fillHeight: true
            Layout.minimumWidth: implicitWidth
            cutTopRight: 0
            borderColor: Theme.accentFaint

            Meters {
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.controlOpen = !ShellState.controlOpen
            }
        }

        // ── Bandeja del sistema (solo si hay iconos) ──
        CutPanel {
            id: trayPanel
            Layout.fillHeight: true
            Layout.minimumWidth: implicitWidth
            visible: SystemTray.items.values.length > 0
            cutTopRight: 0
            borderColor: Theme.accentFaint

            Tray {
                anchors.verticalCenter: parent.verticalCenter
                window: bar
            }
        }

        // ── Reloj ──
        Clock {
            id: clockBlock
            Layout.fillHeight: true
            Layout.minimumWidth: implicitWidth
        }

        GameChip {
            id: gameChip
            Layout.fillHeight: true
            Layout.minimumWidth: implicitWidth
        }
    }
}
