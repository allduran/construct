import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.common
import qs.components
import qs.services

// Menú de energía "DESCONECTAR //": pastillas + acciones secundarias.
PanelWindow {
    id: menu
    visible: Session.menuOpen

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-session"
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
        Session.menuOpen = false;
    }

    // Cerrar y después actuar: así el menú no sale en la pantalla de bloqueo
    // ni se queda "congelado" en pantalla al suspender
    function run(fn) {
        pending.fn = fn;
        close();
        pending.restart();
    }
    Timer {
        id: pending
        property var fn: null
        interval: 150
        onTriggered: if (fn)
            fn()
    }

    // Acciones secundarias (las pastillas van aparte)
    readonly property var actions: [
        {
            key: "L",
            label: "BLOQUEAR",
            fn: () => Session.lock()
        },
        {
            key: "E",
            label: "CERRAR SESIÓN",
            fn: () => Hyprland.dispatch("hl.dsp.exit()")
        },
        {
            key: "R",
            label: "REINICIAR",
            fn: () => Session.reboot()
        },
    ]

    onVisibleChanged: {
        if (!visible)
            return;
        keys.forceActiveFocus();
        openAnim.restart();
        title.glitch();
    }

    // ── Teclado ──
    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            const k = e.text.toUpperCase();
            if (e.key === Qt.Key_Escape)
                menu.close();
            else if (k === "S")
                menu.run(() => Session.suspend());
            else if (k === "A")
                menu.run(() => Session.poweroff());
            else {
                const a = menu.actions.find(x => x.key === k);
                if (!a)
                    return;
                menu.run(a.fn);
            }
            e.accepted = true;
        }
    }

    // ── Fondo ──
    MatrixRain {
        id: rain
        anchors.fill: parent
        opacity: 0.6
        running: Theme.rain && menu.visible
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.6)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: menu.close()
    }

    // ── Contenido ──
    Column {
        id: content
        anchors.centerIn: parent
        spacing: 36
        transform: Translate {
            id: shift
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            GlitchText {
                id: title
                anchors.horizontalCenter: parent.horizontalCenter
                text: "DESCONECTAR //"
                color: Theme.accent
                strength: 4
                font.family: Theme.fontDisplay
                font.pixelSize: 56
                font.letterSpacing: 8
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "elige tu realidad, operador"
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsMd
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 40

            Pill {
                title: "PASTILLA AZUL"
                sub: "suspender · S"
                onClicked: menu.run(() => Session.suspend())
            }
            Pill {
                red: true
                title: "PASTILLA ROJA"
                sub: "apagar · A"
                onClicked: menu.run(() => Session.poweroff())
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Repeater {
                model: menu.actions

                delegate: CutPanel {
                    id: btn
                    required property var modelData

                    width: 200
                    height: 52
                    padding: 0
                    cutTopRight: 12
                    scanlines: false
                    color: hov.hovered ? Qt.alpha(Theme.accent, 0.12) : Theme.surface
                    borderColor: hov.hovered ? Theme.accent : Theme.accentDim

                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: "[" + btn.modelData.key + "]"
                            color: Theme.accent
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fsSm
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: btn.modelData.label
                            color: Theme.text
                            font.family: Theme.fontDisplay
                            font.pixelSize: 13
                            font.letterSpacing: Theme.tracking
                        }
                    }

                    HoverHandler {
                        id: hov
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: menu.run(btn.modelData.fn)
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "ESC · volver a la matriz"
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
        }
    }

    // Entrada: parpadeo + subida
    ParallelAnimation {
        id: openAnim
        SequentialAnimation {
            PropertyAction {
                target: content
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: content
                property: "opacity"
                value: 0.85
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: content
                property: "opacity"
                value: 0.2
            }
            PauseAnimation {
                duration: 50
            }
            NumberAnimation {
                target: content
                property: "opacity"
                to: 1
                duration: 120
            }
        }
        NumberAnimation {
            target: shift
            property: "y"
            from: 24
            to: 0
            duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: rain
            property: "opacity"
            from: 0
            to: 0.6
            duration: 400
        }
    }

    Scanlines {
        anchors.fill: parent
    }
}
