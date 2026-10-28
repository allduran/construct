import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

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

    // ── Interruptor: bloque que se rellena de acento al activarse ──
    component Toggle: CutPanel {
        id: t
        required property string label
        required property string sub
        required property bool on
        signal toggled

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        padding: 14
        cutTopRight: 12
        scanlines: false
        color: on ? Theme.accent : "transparent"
        borderColor: on ? Theme.accent : Theme.accentDim
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 3

            Text {
                text: t.label
                color: t.on ? Theme.accentFg : Theme.text
                font.family: Theme.fontDisplay
                font.pixelSize: 13
                font.letterSpacing: Theme.tracking
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: t.sub
                color: t.on ? Qt.alpha(Theme.accentFg, 0.75) : Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsXs
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: t.toggled()
        }
    }

    // ── Slider de bloques: clic, arrastre o rueda ──
    component BlockSlider: Column {
        id: s
        required property string label
        required property real value          // 0–1
        property color barColor: Theme.accent
        property int blocks: 20
        signal moved(real v)

        Layout.fillWidth: true
        spacing: 6

        Item {
            width: parent.width
            height: lbl.implicitHeight
            Text {
                id: lbl
                text: s.label
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSm
                font.letterSpacing: 1.6
            }
            Text {
                anchors.right: parent.right
                text: Math.round(s.value * 100) + "%"
                color: Theme.textBright
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSm
            }
        }

        Item {
            width: parent.width
            height: 18

            Row {
                anchors.fill: parent
                spacing: 3
                Repeater {
                    model: s.blocks
                    Rectangle {
                        required property int index
                        width: (parent.width - (s.blocks - 1) * 3) / s.blocks
                        height: 18
                        color: index < Math.round(s.value * s.blocks) ? s.barColor : Theme.track
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function pick(x: real) {
                    s.moved(Math.max(0, Math.min(1, x / width)));
                }
                onPressed: e => pick(e.x)
                onPositionChanged: e => {
                    if (pressed)
                        pick(e.x);
                }
                onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
            }
        }
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

            // Cabecera
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
                    text: `uptime ${SysStats.uptimeText} · ${Quickshell.env("USER")}@${Quickshell.env("HOSTNAME") || "construct"}`
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }
            }

            // Interruptores
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Toggle {
                    label: "WI-FI"
                    on: Toggles.wifi
                    sub: Toggles.wifi ? (Network.ssid || "sin conectar") : "apagado"
                    onToggled: Toggles.toggleWifi()
                }
                Toggle {
                    label: "BLUETOOTH"
                    on: Toggles.bluetooth
                    sub: Toggles.bluetooth ? "encendido" : "apagado"
                    onToggled: Toggles.toggleBluetooth()
                }
                Toggle {
                    label: "NO MOLESTAR"
                    on: Toggles.dnd
                    sub: Toggles.dnd ? "transmisiones en silencio" : "transmisiones abiertas"
                    onToggled: Toggles.toggleDnd()
                }
                Toggle {
                    label: "LUZ NOCTURNA"
                    on: Toggles.night
                    sub: Toggles.night ? `${Toggles.nightTemp} K` : "apagada"
                    onToggled: Toggles.toggleNight()
                }
                Toggle {
                    label: "LLUVIA"
                    on: Theme.rain
                    sub: "katakana en launcher y bloqueo"
                    onToggled: Theme.rain = !Theme.rain
                }
                Toggle {
                    label: "SCANLINES"
                    on: Theme.scanlines
                    sub: "líneas CRT en paneles"
                    onToggled: Theme.scanlines = !Theme.scanlines
                }
            }

            // Sliders
            BlockSlider {
                label: Audio.muted ? "VOLUMEN · SILENCIO" : "VOLUMEN"
                value: Audio.muted ? 0 : Audio.volume
                barColor: Audio.muted ? Theme.magenta : Theme.accent
                onMoved: v => Audio.setVolume(v)
            }
            BlockSlider {
                visible: Brightness.available
                label: "BRILLO"
                value: Brightness.value
                barColor: Theme.cyan
                onMoved: v => Brightness.set(v)
            }

            Calendar {
                id: calendar
                Layout.fillWidth: true
                Layout.preferredWidth: 1
            }

            // Hueco para el calendario (7c) y las notificaciones (paso 9)
            Item {
                Layout.fillHeight: true
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
