import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services
import qs.modules.notifications

// Panel de control: interruptores, volumen y brillo.
// (El calendario y las notificaciones se añaden en los pasos siguientes.)
PanelWindow {
    id: cc
    visible: ShellState.controlOpen

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-control"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    function close() {
        ShellState.controlOpen = false;
    }

    onVisibleChanged: {
        if (!visible)
            return;
        calendar.offset = 0;
        keys.forceActiveFocus();
        openAnim.restart();
        title.glitch();
    }

    // Esc cierra
    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: cc.close()
    }

    // Clic fuera del panel = cerrar; dentro, se absorbe
    MouseArea {
        anchors.fill: parent
        onClicked: cc.close()
    }
    MouseArea {
        anchors.fill: panel
    }

    // ── Panel ──
    CutPanel {
        id: panel
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            topMargin: Theme.barHeight + 24     // deja ver la barra
            rightMargin: 16
            bottomMargin: 16
        }
        width: 460
        padding: 20
        cutTopRight: 0
        cutTopLeft: 24
        color: Qt.alpha(Theme.bg, 0.94)
        borderColor: Theme.accentDim
        transform: Translate {
            id: shift
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 18

            // Cabecera + botón de ajustes
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    GlitchText {
                        id: title
                        text: "NODO // OPERADOR"
                        color: Theme.accent
                        font.family: Theme.fontDisplay
                        font.pixelSize: 22
                        font.letterSpacing: Theme.tracking
                    }
                    Text {
                        text: `uptime ${SysStats.uptimeText} · ${Quickshell.env("USER")}`
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                    }
                }

                CutPanel {
                    implicitWidth: setRow.implicitWidth + 24
                    implicitHeight: 44
                    padding: 0
                    cutTopRight: 10
                    scanlines: false
                    color: setArea.containsMouse ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                    borderColor: Theme.accentDim

                    Row {
                        id: setRow
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "⚙"
                            color: Theme.accent
                            font.pixelSize: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "AJUSTES"
                            color: Theme.text
                            font.family: Theme.fontDisplay
                            font.pixelSize: 12
                            font.letterSpacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: setArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ShellState.closeAll();
                            ShellState.settingsOpen = true;
                        }
                    }
                }
            }

            // ── Versículo del día ──
            CutPanel {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                padding: 14
                cutTopRight: 0
                cutBottomLeft: 12
                scanlines: false
                color: verseArea.containsMouse ? Qt.alpha(Theme.accent, 0.06) : "transparent"
                borderColor: Theme.accentFaint

                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: `VERSÍCULO // DÍA ${Verse.dayOfYear}`
                        color: Theme.accent
                        font.family: Theme.fontDisplay
                        font.pixelSize: 12
                        font.letterSpacing: Theme.tracking
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: Verse.available ? "«" + Verse.text + "»" : "añade tu RVR1960 en ~/.local/share/construct/biblia/rvr1960.json"
                        color: Verse.available ? Theme.textBright : Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Verse.available ? Theme.fsMd : Theme.fsXs
                        lineHeight: 1.3
                    }
                    Text {
                        text: Verse.reference + " · " + Verse.version + (Verse.available ? "   ·   clic: copiar" : "")
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsXs
                    }
                }

                MouseArea {
                    id: verseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: Verse.available
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Verse.copy()
                }
            }

            Calendar {
                id: calendar
                Layout.fillWidth: true
                Layout.preferredWidth: 1
            }

            // ── Transmisiones: historial de notificaciones ──
            Item {
                Layout.fillWidth: true
                implicitHeight: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.StyledText
                    text: `TRANSMISIONES <font color="${Theme.textDim}">· ${Notifs.count}</font>`
                    color: Theme.accent
                    font.family: Theme.fontDisplay
                    font.pixelSize: 13
                    font.letterSpacing: Theme.tracking
                }

                CutPanel {
                    id: purge
                    visible: Notifs.count > 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    padding: 8
                    cutTopRight: 8
                    scanlines: false
                    color: purgeArea.containsMouse ? Qt.alpha(Theme.magenta, 0.15) : "transparent"
                    borderColor: purgeArea.containsMouse ? Theme.magenta : Theme.accentDim

                    Text {
                        text: "PURGAR"
                        color: purgeArea.containsMouse ? Theme.magenta : Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsXs
                        font.letterSpacing: 1.6
                    }
                    MouseArea {
                        id: purgeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                // La más nueva arriba
                model: Notifs.list.slice().reverse()

                delegate: NotifCard {
                    required property var modelData
                    notif: modelData
                    popup: false
                    width: ListView.view.width
                }

                // Vacío
                Text {
                    visible: parent.count === 0
                    anchors.centerIn: parent
                    text: "sin transmisiones · canal limpio_"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }
            }
        }
    }

    // Entrada: parpadeo + desliza desde la derecha
    ParallelAnimation {
        id: openAnim
        SequentialAnimation {
            PropertyAction {
                target: panel
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: panel
                property: "opacity"
                value: 0.85
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: panel
                property: "opacity"
                value: 0.2
            }
            PauseAnimation {
                duration: 50
            }
            NumberAnimation {
                target: panel
                property: "opacity"
                to: 1
                duration: 120
            }
        }
        NumberAnimation {
            target: shift
            property: "x"
            from: 40
            to: 0
            duration: 260
            easing.type: Easing.OutCubic
        }
    }
}
