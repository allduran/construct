import Quickshell
import QtQuick
import qs.common
import qs.components
import qs.services

// Grupo de notificaciones de una misma app.
// Plegado: solo la más nueva, con "pila" debajo y un contador.
// Ratón encima: se despliegan todas (y en popups no caduca ninguna).
Item {
    id: grp
    required property var items          // notificaciones de la app, la más nueva primero
    // Al desaparecer la última, el delegado vive un instante con items vacío: se conserva la anterior
    property var shown: items
    onItemsChanged: if (items.length > 0)
        shown = items
    else
        shown = shown.filter(n => n)         // sin objetos ya destruidos (la app cerró la notificación)
    property bool popup: true

    readonly property bool stacked: shown.length > 1
    readonly property bool expanded: stacked && hover.hovered

    implicitHeight: col.implicitHeight + (stacked && !expanded ? 8 : 0)
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: hover
    }

    // Pila bajo la tarjeta cuando está plegado
    Repeater {
        model: grp.stacked && !grp.expanded ? 2 : 0
        delegate: CutPanel {
            required property int index
            x: 14 + index * 8                       // arranca donde acaba el chaflán de la tarjeta
            y: first.height - 4 + (index + 1) * 4
            width: grp.width - 14 - 8 - index * 16
            height: 4
            padding: 0
            scanlines: false
            cutTopRight: 0
            cutBottomLeft: Theme.cutXs
            color: Qt.alpha(Theme.bg, 0.94)
            borderColor: Qt.alpha(first.tone, 0.6 - index * 0.25)
            z: -1 - index
        }
    }

    Column {
        id: col
        width: grp.width
        spacing: 6

        NotifCard {
            id: first
            notif: grp.shown[0]
            popup: grp.popup
            group: grp.shown
            held: grp.expanded
            width: grp.width
        }

        // El resto solo existe mientras está desplegado
        Repeater {
            model: ScriptModel {
                values: grp.expanded ? grp.shown.slice(1) : []
            }
            delegate: NotifCard {
                required property var modelData
                notif: modelData
                popup: grp.popup
                animateIn: false
                group: grp.shown
                held: true
                width: grp.width
                // Fundido de entrada al desplegar
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }
        }
    }

    // Contador "▼ +N" en la esquina inferior derecha (indica que se despliega)
    CutPanel {
        visible: grp.stacked && !grp.expanded
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: first.height - height / 2
        width: badge.implicitWidth + 12
        height: badge.implicitHeight + 4
        padding: 0
        scanlines: false
        cutTopRight: Theme.cutXs
        color: Theme.bg
        borderColor: first.tone
        Row {
            id: badge
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "▼"
                color: first.tone
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsXs - 2
            }
            Text {
                text: `+${grp.shown.length - 1}`
                color: first.tone
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsXs
            }
        }
    }
}
