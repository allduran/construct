import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.common

// Bandeja del sistema (StatusNotifierItem).
Row {
    id: root
    spacing: 10

    // Ventana de la barra: los menús de las apps se abren anclados a ella
    required property var window

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: slot
            required property SystemTrayItem modelData

            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onClicked: e => {
                if (e.button === Qt.LeftButton && !modelData.onlyMenu) {
                    modelData.activate();                 // abrir / mostrar la app
                } else if (e.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (modelData.hasMenu) {
                    // Posición en coordenadas de la ventana, justo debajo del icono
                    const p = slot.mapToItem(null, 0, slot.height + 10);
                    modelData.display(root.window, p.x, p.y);
                }
            }

            onWheel: w => modelData.scroll(w.angleDelta.y / 120, false)

            IconImage {
                anchors.fill: parent
                source: slot.modelData.icon

                // Monocromo fósforo; color original al pasar el ratón
                layer.enabled: !slot.containsMouse
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: Theme.accent
                }
            }
        }
    }
}
