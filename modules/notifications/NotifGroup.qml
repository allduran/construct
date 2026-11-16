import QtQuick
import qs.common
import qs.services

// Grupo de notificaciones de una misma app.
// Plegado: solo la más nueva, con "pila" debajo y un contador.
// Ratón encima: se despliegan todas (y en popups no caduca ninguna).
Item {
    id: grp
    required property var items          // notificaciones de la app, la más nueva primero
    property bool popup: true

    readonly property bool stacked: items.length > 1
    readonly property bool expanded: stacked && hover.hovered

    implicitHeight: col.implicitHeight + (stacked && !expanded ? 8 : 0)

    HoverHandler {
        id: hover
    }

    // Pila bajo la tarjeta cuando está plegado
    Repeater {
        model: grp.stacked && !grp.expanded ? 2 : 0
        delegate: Rectangle {
            required property int index
            x: 8 + index * 8
            y: first.height - 4 + (index + 1) * 4
            width: grp.width - 16 - index * 16
            height: 4
            color: Qt.alpha(Theme.bg, 0.94)
            border.color: Qt.alpha(Theme.accentDim, 0.8 - index * 0.3)
            border.width: 1
            z: -1 - index
        }
    }

    Column {
        id: col
        width: grp.width
        spacing: 6

        NotifCard {
            id: first
            notif: grp.items[0]
            popup: grp.popup
            group: grp.items
            held: grp.expanded
            width: grp.width
        }

        // El resto solo existe mientras está desplegado
        Repeater {
            model: grp.expanded ? grp.items.slice(1) : []
            delegate: NotifCard {
                required property var modelData
                notif: modelData
                popup: grp.popup
                animateIn: false
                group: grp.items
                held: true
                width: grp.width
            }
        }
    }

    // Contador "+N" en la esquina inferior derecha
    Rectangle {
        visible: grp.stacked && !grp.expanded
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: first.height - height / 2
        width: badge.implicitWidth + 12
        height: badge.implicitHeight + 4
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1
        Text {
            id: badge
            anchors.centerIn: parent
            text: `+${grp.items.length - 1}`
            color: Theme.accent
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsXs
        }
    }
}
