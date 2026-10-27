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
        anchors.fill: parent
        spacing: Theme.gap

        // ── Izquierda: logo + espacios de trabajo ──
        CutPanel {
            Layout.fillHeight: true
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
            cutTopRight: 0
            borderColor: Theme.accentFaint

            ActiveWindow {
                anchors.fill: parent
            }
        }

        // ── Derecha: medidores ──
        // ── Derecha: medidores ──
        CutPanel {
            Layout.fillHeight: true
            cutTopRight: 0
            borderColor: Theme.accentFaint

            Meters {
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── Bandeja del sistema (solo si hay iconos) ──
        CutPanel {
            Layout.fillHeight: true
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
            Layout.fillHeight: true
        }
    }
}
