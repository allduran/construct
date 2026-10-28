import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Tarjeta de notificación ("transmisión").
// popup: true  → flotante: se oculta sola y la ✕ solo la oculta
// popup: false → en el historial: la ✕ la descarta
CutPanel {
    id: card
    required property var notif
    property bool popup: true

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property color tone: critical ? Theme.magenta : notif.urgency === NotificationUrgency.Low ? Theme.textDim : Theme.accent
    readonly property var defaultAction: notif.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: notif.actions.filter(a => a.identifier !== "default")
    readonly property string image: notif.image || (notif.appIcon ? Quickshell.iconPath(notif.appIcon, true) : "")

    width: 420
    padding: 14
    cutTopRight: 0
    cutBottomLeft: 14
    color: critical ? "#0a0206" : Qt.alpha(Theme.bg, 0.94)
    borderColor: tone

    function close(): void {
        if (popup)
            Notifs.hidePopup(notif);
        else
            notif.dismiss();
    }

    // Barra gruesa a la izquierda, como el toast del diseño
    Rectangle {
        parent: card
        width: 4
        height: card.height - card.cutBottomLeft
        color: card.tone
    }

    // Clic en la tarjeta = acción por defecto de la app (abrir el chat, etc.)
    MouseArea {
        anchors.fill: parent
        cursorShape: card.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (card.defaultAction)
                card.defaultAction.invoke();
            card.close();
        }
    }

    // Ratón encima = no se oculta
    HoverHandler {
        id: hover
    }

    Timer {
        interval: card.notif.expireTimeout > 0 ? card.notif.expireTimeout : 6000
        running: card.popup && !card.critical && !hover.hovered
        onTriggered: Notifs.hidePopup(card.notif)
    }

    ColumnLayout {
        width: card.width - card.padding * 2
        spacing: 6

        // Cabecera: app · hora · cerrar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: (card.notif.appName || "SISTEMA").toUpperCase()
                color: card.tone
                font.family: Theme.fontDisplay
                font.pixelSize: 12
                font.letterSpacing: Theme.tracking
            }
            Text {
                text: Qt.formatTime(new Date(Notifs.times[card.notif.id] ?? Date.now()), "HH:mm")
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsXs
            }
            Text {
                text: "✕"
                color: closeArea.containsMouse ? Theme.textBright : Theme.textDim
                font.pixelSize: 13
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -6          // zona de clic algo mayor que la ✕
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.close()
                }
            }
        }

        // Imagen + texto
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Image {
                visible: card.image !== ""
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                Layout.alignment: Qt.AlignTop
                source: card.image
                sourceSize: Qt.size(88, 88)
                fillMode: Image.PreserveAspectCrop
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: card.notif.summary
                    color: Theme.textBright
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsMd
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.notif.body
                    textFormat: Text.StyledText          // negritas y enlaces que manden las apps
                    color: Theme.text
                    linkColor: Theme.cyan
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                    wrapMode: Text.Wrap
                    maximumLineCount: card.popup ? 4 : 2
                    elide: Text.ElideRight
                    onLinkActivated: l => Qt.openUrlExternally(l)
                }
            }
        }

        // Botones de acción (Responder, Aceptar…)
        Row {
            visible: card.buttons.length > 0
            spacing: 6

            Repeater {
                model: card.buttons

                delegate: CutPanel {
                    id: btn
                    required property var modelData
                    padding: 8
                    cutTopRight: 8
                    scanlines: false
                    color: btnArea.containsMouse ? Qt.alpha(card.tone, 0.15) : "transparent"
                    borderColor: Qt.alpha(card.tone, 0.6)

                    Text {
                        text: btn.modelData.text.toUpperCase()
                        color: card.tone
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsXs
                        font.letterSpacing: 1.2
                    }
                    MouseArea {
                        id: btnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            btn.modelData.invoke();
                            card.close();
                        }
                    }
                }
            }
        }
    }

    // Entrada: desliza desde la derecha con parpadeo
    transform: Translate {
        id: shift
    }
    Component.onCompleted: if (popup)
        enter.restart()

    ParallelAnimation {
        id: enter
        NumberAnimation {
            target: shift
            property: "x"
            from: 60
            to: 0
            duration: 240
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            PropertyAction {
                target: card
                property: "opacity"
                value: 0.3
            }
            PauseAnimation {
                duration: 50
            }
            PropertyAction {
                target: card
                property: "opacity"
                value: 0.9
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: card
                property: "opacity"
                value: 0.5
            }
            NumberAnimation {
                target: card
                property: "opacity"
                to: 1
                duration: 120
            }
        }
    }
}
