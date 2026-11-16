import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.common
import qs.services

// Notificaciones flotantes, arriba a la derecha bajo la barra. La más nueva arriba.
PanelWindow {
    id: win
    visible: Notifs.popups.length > 0

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-notifs"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barHeight + 24
        right: 16
    }
    implicitWidth: 420
    implicitHeight: Math.max(1, list.contentHeight)
    color: "transparent"

    ListView {
        id: list
        anchors.fill: parent
        interactive: false
        // popups ya va del más nuevo al más viejo: el más nuevo arriba, agrupadas por app
        verticalLayoutDirection: ListView.TopToBottom
        model: ScriptModel {
            values: Notifs.appsOf(Notifs.popups)
        }

        delegate: Item {
            id: slot
            required property string modelData          // clave de la app

            width: list.width
            height: group.implicitHeight + 10

            NotifGroup {
                id: group
                width: slot.width
                items: Notifs.popups.filter(n => Notifs.appKey(n) === slot.modelData)
                popup: true
            }
        }
    }
}
