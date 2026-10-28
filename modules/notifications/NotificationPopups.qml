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
        // El último en llegar es el último del modelo: de abajo arriba = el más nuevo arriba
        verticalLayoutDirection: ListView.BottomToTop
        model: Notifs.tracked

        delegate: Item {
            id: slot
            required property var modelData
            readonly property bool shown: Notifs.popups.includes(modelData)

            width: list.width
            height: shown ? card.height + 10 : 0     // los ocultos no ocupan sitio
            visible: shown

            NotifCard {
                id: card
                notif: slot.modelData
                popup: true
            }
        }
    }
}
