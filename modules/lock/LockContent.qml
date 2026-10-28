import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.components
import qs.services

// Contenido de la pantalla de bloqueo (uno por monitor).
Item {
    id: root

    readonly property var es: Qt.locale("es_ES")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Component.onCompleted: input.forceActiveFocus()

    // Contraseña vaciada por Lock (tras intentarlo) → vaciar también el campo
    Connections {
        target: Lock
        function onPasswordChanged() {
            if (Lock.password === "")
                input.text = "";
        }
        function onFailedChanged() {
            if (Lock.failed)
                shake.restart();
        }
    }

    // ── Fondo: lluvia + viñeta radial oscura en el centro ──
    MatrixRain {
        anchors.fill: parent
        opacity: 0.7
        running: Theme.rain && Lock.locked
    }

    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.width / 2
                centerY: root.height * 0.42
                centerRadius: root.width * 0.6
                focalX: centerX
                focalY: centerY
                GradientStop {
                    position: 0.0
                    color: Qt.alpha(Theme.bg, 0.92)
                }
                GradientStop {
                    position: 0.4
                    color: Qt.alpha(Theme.bg, 0.7)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.alpha(Theme.bg, 0.25)
                }
            }
            PathRectangle {
                width: root.width
                height: root.height
            }
        }
    }

    // ── Línea superior ──
    Item {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 28
        }
        height: 20

        Text {
            text: "CNSTRCT// v0.1"
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
            font.letterSpacing: Theme.tracking
        }
        Text {
            readonly property var bat: UPower.displayDevice
            anchors.right: parent.right
            text: [Network.connected ? "WIFI " + Network.ssid.toUpperCase() : "SIN RED", bat?.isLaptopBattery ? "BAT " + Math.round(bat.percentage * 100) + "%" : ""].filter(s => s).join(" · ")
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
            font.letterSpacing: Theme.tracking
        }
    }

    // ── Reloj ──
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.16
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "SESIÓN BLOQUEADA · NODO 0x1F"
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: 13
            font.letterSpacing: 5
        }
        GlitchText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Theme.accent
            strength: 6
            font.family: Theme.fontDisplay
            font.pixelSize: 220
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.date.toLocaleString(root.es, "dddd · d MMMM yyyy").toUpperCase()
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: 22
            font.letterSpacing: 6
        }
    }

    // ── Contraseña ──
    Column {
        id: form
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.55
        width: 600
        spacing: 12
        transform: Translate {
            id: shakeX
        }

        Item {
            width: parent.width
            height: idLabel.implicitHeight
            Text {
                id: idLabel
                text: "IDENTIFICACIÓN DE OPERADOR"
                color: Lock.failed ? Theme.magenta : Theme.accent
                font.family: Theme.fontDisplay
                font.pixelSize: 13
                font.letterSpacing: Theme.tracking
            }
            Text {
                anchors.right: parent.right
                text: Quickshell.env("USER")
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: 13
            }
        }

        CutPanel {
            width: parent.width
            height: 64
            padding: 20
            cutTopRight: 18
            cutBottomLeft: 18
            color: Qt.alpha(Theme.bg, 0.94)
            borderColor: Lock.failed ? Theme.magenta : Theme.accent

            Row {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 14

                Text {
                    id: gt
                    anchors.verticalCenter: parent.verticalCenter
                    text: ">"
                    color: Theme.accent
                    font.family: Theme.fontMono
                    font.pixelSize: 22
                }

                TextInput {
                    id: input
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - gt.width - status.width - parent.spacing * 2
                    echoMode: TextInput.Password
                    passwordCharacter: "■"
                    enabled: !Lock.busy
                    color: Theme.textBright
                    font.family: Theme.fontMono
                    font.pixelSize: 22
                    font.letterSpacing: 4
                    clip: true

                    onTextChanged: Lock.password = text
                    Keys.onReturnPressed: Lock.tryUnlock()
                    Keys.onEnterPressed: Lock.tryUnlock()
                    Keys.onEscapePressed: text = ""

                    cursorDelegate: Rectangle {
                        id: caret
                        width: 12
                        color: Theme.accent
                        Timer {
                            interval: 530
                            running: input.activeFocus
                            repeat: true
                            onTriggered: caret.opacity = caret.opacity > 0 ? 0 : 1
                        }
                    }
                }

                Text {
                    id: status
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lock.busy ? "VERIFICANDO…" : "↵ ENTRAR"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                    font.letterSpacing: 1.6
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Lock.failed ? "ACCESO DENEGADO — inténtalo de nuevo" : "Despierta, operador. La matriz te espera."
            color: Lock.failed ? Theme.magenta : Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: 13
        }
    }

    // Contraseña incorrecta: el formulario tiembla
    SequentialAnimation {
        id: shake
        loops: 1
        NumberAnimation {
            target: shakeX
            property: "x"
            to: -14
            duration: 40
        }
        NumberAnimation {
            target: shakeX
            property: "x"
            to: 12
            duration: 50
        }
        NumberAnimation {
            target: shakeX
            property: "x"
            to: -8
            duration: 50
        }
        NumberAnimation {
            target: shakeX
            property: "x"
            to: 4
            duration: 50
        }
        NumberAnimation {
            target: shakeX
            property: "x"
            to: 0
            duration: 40
        }
    }

    // ── Elige ──
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 70
        spacing: 22

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "ELIGE"
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: 13
            font.letterSpacing: 8
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 40

            Pill {
                title: "PASTILLA AZUL"
                sub: "suspender · seguir soñando"
                onClicked: Session.suspend()
            }
            Pill {
                red: true
                title: "PASTILLA ROJA"
                sub: "apagar · salir de la matriz"
                onClicked: Session.poweroff()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "REINICIAR"
            color: rebootHover.hovered ? Theme.textBright : Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
            font.letterSpacing: Theme.tracking
            HoverHandler {
                id: rebootHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: Session.reboot()
            }
        }
    }

    // CRT
    Scanlines {
        anchors.fill: parent
    }
}
