import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// AJUSTES //: ventana de ajustes con navegación por secciones.
PanelWindow {
    id: st
    visible: ShellState.settingsOpen

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-settings"
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

    readonly property var sections: [
        {
            title: "SISTEMA",
            sub: "avisos, energía y modo juego"
        },
        {
            title: "RED",
            sub: "conexiones inalámbricas"
        },
        {
            title: "PANTALLA",
            sub: "brillo y luz nocturna"
        },
        {
            title: "SONIDO",
            sub: "volumen y salida de audio"
        },
        {
            title: "APARIENCIA",
            sub: "efectos y fondo"
        },
    ]
    property int section: 0

    // Salidas de audio reales (sin las corrientes de cada app)
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    function close() {
        ShellState.settingsOpen = false;
    }

    // Cambia la temperatura de la luz nocturna (si está encendida, la reaplica)
    function setNightTemp(k: int) {
        Toggles.nightTemp = k;
        if (Toggles.night)
            Quickshell.execDetached(["sh", "-c", 'pkill -x hyprsunset; setsid hyprsunset -t "$1" >/dev/null 2>&1 &', "sh", String(k)]);
    }

    onVisibleChanged: {
        if (!visible)
            return;
        keys.forceActiveFocus();
        openAnim.restart();
        title.glitch();
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            const d = parseInt(e.text);
            if (e.key === Qt.Key_Escape)
                st.close();
            else if (e.key === Qt.Key_Tab)
                st.section = (st.section + 1) % st.sections.length;
            else if (e.key === Qt.Key_Backtab)
                st.section = (st.section + st.sections.length - 1) % st.sections.length;
            else if (d >= 1 && d <= st.sections.length)
                st.section = d - 1;
            else
                return;
            e.accepted = true;
        }
    }

    // ── Piezas propias de esta ventana ──

    // Título de bloque dentro de una sección
    component Heading: Text {
        Layout.fillWidth: true
        Layout.topMargin: 6
        color: Theme.textDim
        font.family: Theme.fontDisplay
        font.pixelSize: 12
        font.letterSpacing: Theme.tracking
    }

    // Selector de una opción entre varias (perfil de energía, salida de audio…)
    component Choice: CutPanel {
        id: ch
        required property string label
        property string sub: ""
        required property bool on
        signal picked

        Layout.fillWidth: true
        implicitHeight: sub ? 56 : 44
        padding: 12
        cutTopRight: 10
        scanlines: false
        color: on ? Qt.alpha(Theme.accent, 0.14) : chArea.containsMouse ? Qt.alpha(Theme.accent, 0.06) : "transparent"
        borderColor: on ? Theme.accent : Theme.accentFaint

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 10
                color: ch.on ? Theme.accent : "transparent"
                border.color: ch.on ? Theme.accent : Theme.accentDim
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: ch.label
                    color: ch.on ? Theme.textBright : Theme.text
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsMd
                }
                Text {
                    visible: ch.sub !== ""
                    text: ch.sub
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsXs
                }
            }
        }
        MouseArea {
            id: chArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ch.picked()
        }
    }

    // ── Fondo ──
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.7)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: st.close()
    }

    // ── Ventana ──
    CutPanel {
        id: win
        width: 1000
        height: 640
        anchors.centerIn: parent
        padding: 0
        cutTopRight: 24
        cutBottomLeft: 24
        color: Qt.alpha(Theme.bg, 0.96)
        borderColor: Theme.accentDim
        transform: Translate {
            id: shift
        }

        MouseArea {
            parent: win
            anchors.fill: parent
            z: -1
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Navegación ──
            ColumnLayout {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                Layout.margins: 24
                spacing: 6

                GlitchText {
                    id: title
                    text: "AJUSTES //"
                    color: Theme.accent
                    font.family: Theme.fontDisplay
                    font.pixelSize: 28
                    font.letterSpacing: 5
                }
                Text {
                    Layout.bottomMargin: 18
                    text: "construct · " + Quickshell.env("USER")
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }

                Repeater {
                    model: st.sections
                    delegate: CutPanel {
                        id: nav
                        required property var modelData
                        required property int index
                        readonly property bool on: index === st.section

                        Layout.fillWidth: true
                        implicitHeight: 48
                        padding: 14
                        cutTopRight: 0
                        scanlines: false
                        color: on ? Theme.accent : navArea.containsMouse ? Qt.alpha(Theme.accent, 0.08) : "transparent"
                        borderColor: on ? Theme.accent : "transparent"

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Text {
                                text: "0" + (nav.index + 1)
                                color: nav.on ? Theme.accentFg : Theme.accentDim
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fsSm
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: nav.modelData.title
                                color: nav.on ? Theme.accentFg : Theme.text
                                font.family: Theme.fontDisplay
                                font.pixelSize: 13
                                font.letterSpacing: Theme.tracking
                            }
                        }
                        MouseArea {
                            id: navArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: st.section = nav.index
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    text: "1–5 sección · TAB siguiente · ESC cerrar"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsXs
                }
            }

            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Theme.accentFaint
            }

            // ── Contenido de la sección ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 28
                spacing: 14

                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: st.sections[st.section].title
                        color: Theme.textBright
                        font.family: Theme.fontDisplay
                        font.pixelSize: 22
                        font.letterSpacing: Theme.tracking
                    }
                    Text {
                        text: st.sections[st.section].sub
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.accentFaint
                }

                // 01 SISTEMA
                ColumnLayout {
                    visible: st.section === 0
                    Layout.fillWidth: true
                    spacing: 10

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        Toggle {
                            label: "NO MOLESTAR"
                            on: Toggles.dnd
                            sub: Toggles.dnd ? "solo pasan las críticas" : "transmisiones abiertas"
                            onToggled: Toggles.toggleDnd()
                        }
                        Toggle {
                            label: "MODO JUEGO"
                            on: Theme.gameMode
                            sub: Theme.gameMode ? "activo · SUPER + TAB" : "SUPER + TAB"
                            onToggled: GameMode.toggle()
                        }
                    }

                    Heading {
                        text: "PERFIL DE ENERGÍA"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Choice {
                            label: "AHORRO"
                            on: PowerProfiles.profile === PowerProfile.PowerSaver
                            onPicked: PowerProfiles.profile = PowerProfile.PowerSaver
                        }
                        Choice {
                            label: "EQUILIBRADO"
                            on: PowerProfiles.profile === PowerProfile.Balanced
                            onPicked: PowerProfiles.profile = PowerProfile.Balanced
                        }
                        Choice {
                            visible: PowerProfiles.hasPerformanceProfile
                            label: "RENDIMIENTO"
                            on: PowerProfiles.profile === PowerProfile.Performance
                            onPicked: PowerProfiles.profile = PowerProfile.Performance
                        }
                    }
                }

                // 02 RED
                GridLayout {
                    visible: st.section === 1
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    Toggle {
                        label: "WI-FI"
                        on: Toggles.wifi
                        sub: Toggles.wifi ? (Network.ssid ? `${Network.ssid} · ${Network.signal}%` : "sin conectar") : "apagado"
                        onToggled: Toggles.toggleWifi()
                    }
                    Toggle {
                        label: "BLUETOOTH"
                        on: Toggles.bluetooth
                        sub: Toggles.bluetooth ? "encendido" : "apagado"
                        onToggled: Toggles.toggleBluetooth()
                    }
                }

                // 03 PANTALLA
                ColumnLayout {
                    visible: st.section === 2
                    Layout.fillWidth: true
                    spacing: 14

                    BlockSlider {
                        visible: Brightness.available
                        label: "BRILLO"
                        value: Brightness.value
                        barColor: Theme.cyan
                        onMoved: v => Brightness.set(v)
                    }
                    Toggle {
                        label: "LUZ NOCTURNA"
                        on: Toggles.night
                        sub: Toggles.night ? `encendida · ${Toggles.nightTemp} K` : "apagada"
                        onToggled: Toggles.toggleNight()
                    }
                    // 2500 K (muy cálida) – 6500 K (neutra)
                    BlockSlider {
                        label: "TEMPERATURA"
                        value: (Toggles.nightTemp - 2500) / 4000
                        valueText: Toggles.nightTemp + " K"
                        barColor: Theme.yellow
                        onMoved: v => st.setNightTemp(Math.round((2500 + v * 4000) / 100) * 100)
                    }
                }

                // 04 SONIDO
                ColumnLayout {
                    visible: st.section === 3
                    Layout.fillWidth: true
                    spacing: 10

                    BlockSlider {
                        label: Audio.muted ? "VOLUMEN · SILENCIO" : "VOLUMEN"
                        value: Audio.muted ? 0 : Audio.volume
                        barColor: Audio.muted ? Theme.magenta : Theme.accent
                        onMoved: v => Audio.setVolume(v)
                    }
                    Toggle {
                        label: "SILENCIO"
                        on: Audio.muted
                        sub: Audio.muted ? "salida silenciada" : "sonando"
                        onToggled: Audio.toggleMute()
                    }

                    Heading {
                        text: "SALIDA"
                    }
                    Repeater {
                        model: st.sinks
                        delegate: Choice {
                            required property var modelData
                            label: modelData.description || modelData.nickname || modelData.name
                            sub: modelData.name
                            on: Pipewire.defaultAudioSink === modelData
                            onPicked: Pipewire.preferredDefaultAudioSink = modelData
                        }
                    }
                }

                // 05 APARIENCIA
                ColumnLayout {
                    visible: st.section === 4
                    Layout.fillWidth: true
                    spacing: 10

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 8
                        Toggle {
                            label: "LLUVIA"
                            on: Theme.rain
                            sub: "launcher y bloqueo"
                            onToggled: Theme.rain = !Theme.rain
                        }
                        Toggle {
                            label: "SCANLINES"
                            on: Theme.scanlines
                            sub: "líneas CRT"
                            onToggled: Theme.scanlines = !Theme.scanlines
                        }
                        Toggle {
                            label: "GLITCH"
                            on: Theme.glitch
                            sub: "títulos"
                            onToggled: Theme.glitch = !Theme.glitch
                        }
                    }

                    Heading {
                        text: "FONDO"
                    }
                    CutPanel {
                        Layout.fillWidth: true
                        implicitHeight: 120
                        padding: 0
                        cutTopRight: 14
                        scanlines: false
                        color: "transparent"
                        borderColor: Theme.accentDim

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 16

                            WallImage {
                                Layout.preferredWidth: 178
                                Layout.fillHeight: true
                                source: Wallpapers.current ? "file://" + Wallpapers.current : ""
                                filter: Wallpapers.filter
                                intensity: Wallpapers.intensity
                            }
                            Column {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    width: parent.width
                                    elide: Text.ElideMiddle
                                    text: Wallpapers.current.split("/").pop() || "sin fondo"
                                    color: Theme.textBright
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fsMd
                                }
                                Text {
                                    text: `${Wallpapers.filterNames[Wallpapers.filter]} · ${Math.round(Wallpapers.intensity * 100)}%`
                                    color: Theme.textDim
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fsSm
                                }
                            }
                            CutPanel {
                                implicitWidth: sigText.implicitWidth + 28
                                implicitHeight: 40
                                padding: 0
                                cutTopRight: 0
                                scanlines: false
                                color: Theme.accent
                                borderColor: Theme.accent
                                Text {
                                    id: sigText
                                    anchors.centerIn: parent
                                    text: "ABRIR SEÑAL"
                                    color: Theme.accentFg
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: 12
                                    font.letterSpacing: 2
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ShellState.closeAll();
                                        ShellState.wallpaperOpen = true;
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    // Entrada
    ParallelAnimation {
        id: openAnim
        SequentialAnimation {
            PropertyAction {
                target: win
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: win
                property: "opacity"
                value: 0.85
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: win
                property: "opacity"
                value: 0.2
            }
            PauseAnimation {
                duration: 50
            }
            NumberAnimation {
                target: win
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
    }

    Scanlines {
        anchors.fill: parent
        lineOpacity: 0.2
    }
}
