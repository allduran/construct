import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick
import qs.common
import qs.components
import qs.services

// ENLACE NEURAL // AUDIO: reproductor MPRIS bajo el chip de la barra.
PanelWindow {
    id: mp
    visible: ShellState.mediaOpen && Media.player !== null

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-media"
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

    readonly property var p: Media.player
    readonly property bool playing: p?.isPlaying ?? false

    function close() {
        ShellState.mediaOpen = false;
    }

    onVisibleChanged: {
        if (!visible)
            return;
        keys.forceActiveFocus();
        openAnim.restart();
    }

    // Teclado: Espacio play/pausa · ←→ pista · Esc cerrar
    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape)
                mp.close();
            else if (e.key === Qt.Key_Space)
                Media.toggle();
            else if (e.key === Qt.Key_Right)
                Media.next();
            else if (e.key === Qt.Key_Left)
                Media.previous();
            else
                return;
            e.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mp.close()
    }

    // Botón de control (texto como icono)
    component Ctrl: CutPanel {
        id: c
        required property string glyph
        property bool primary: false
        property bool on: false
        property bool enabledCtl: true
        signal clicked

        width: primary ? 64 : 52
        height: 52
        padding: 0
        cutTopRight: primary ? 12 : 0
        cutBottomLeft: primary ? 12 : 0
        scanlines: false
        opacity: enabledCtl ? 1 : 0.35
        color: primary ? Theme.accent : on ? Qt.alpha(Theme.accent, 0.15) : cArea.containsMouse ? Qt.alpha(Theme.accent, 0.08) : "transparent"
        borderColor: primary || on ? Theme.accent : Theme.accentDim

        Text {
            anchors.centerIn: parent
            text: c.glyph
            color: c.primary ? Theme.accentFg : c.on ? Theme.accent : Theme.text
            font.family: Theme.fontMono
            font.pixelSize: c.primary ? 20 : 16
            font.weight: Font.Bold
        }
        MouseArea {
            id: cArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: c.enabledCtl
            cursorShape: Qt.PointingHandCursor
            onClicked: c.clicked()
        }
    }

    // ── Panel ──
    CutPanel {
        id: panel
        width: 500
        x: Math.max(16, Math.min(mp.width - width - 16, ShellState.mediaX))
        y: Theme.barHeight + 24
        padding: 20
        cutTopRight: 0
        cutBottomRight: 22
        color: Qt.alpha(Theme.bg, 0.95)
        borderColor: Theme.accentDim
        transform: Translate {
            id: shift
        }

        MouseArea {
            parent: panel
            anchors.fill: parent
            z: -1
        }

        Column {
            width: panel.width - panel.padding * 2
            spacing: 16

            // Cabecera + reproductores
            Item {
                width: parent.width
                height: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ENLACE NEURAL // AUDIO"
                    color: Theme.accent
                    font.family: Theme.fontDisplay
                    font.pixelSize: 13
                    font.letterSpacing: Theme.tracking
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    visible: Media.players.length > 1

                    Repeater {
                        model: Media.players
                        delegate: Rectangle {
                            id: tab
                            required property var modelData
                            readonly property bool on: modelData === mp.p
                            width: tabText.implicitWidth + 20
                            height: 32
                            color: on ? Theme.accent : "transparent"
                            border.color: on ? Theme.accent : Theme.accentDim
                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: (tab.modelData.identity || "?").toUpperCase()
                                color: tab.on ? Theme.accentFg : Theme.textDim
                                font.family: Theme.fontDisplay
                                font.pixelSize: 11
                                font.letterSpacing: 1.6
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Media.preferred = tab.modelData.identity
                            }
                        }
                    }
                }
            }

            // Portada + datos
            Row {
                width: parent.width
                spacing: 18

                CutPanel {
                    width: 132
                    height: 132
                    padding: 0
                    cutTopRight: 14
                    scanlines: false
                    color: Qt.alpha(Theme.accent, 0.05)
                    borderColor: Theme.accentDim

                    Image {
                        id: art
                        anchors.fill: parent
                        anchors.margins: 1
                        source: mp.p?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(264, 264)
                        asynchronous: true
                    }
                    Text {
                        visible: art.status !== Image.Ready
                        anchors.centerIn: parent
                        text: "♪"
                        color: Theme.accentDim
                        font.pixelSize: 48
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 132 - 18
                    spacing: 6

                    Text {
                        width: parent.width
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        text: mp.p?.trackTitle || "sin título"
                        color: Theme.textBright
                        font.family: Theme.fontMono
                        font.pixelSize: 18
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: mp.p?.trackArtist ?? ""
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsMd
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        visible: text !== ""
                        text: mp.p?.trackAlbum ?? ""
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                    }
                    Text {
                        topPadding: 6
                        text: (mp.playing ? "▶ SONANDO" : "❚❚ EN PAUSA") + " · " + (mp.p?.identity ?? "").toUpperCase()
                        color: Theme.accent
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsXs
                        font.letterSpacing: 1.6
                    }
                }
            }

            // Progreso en bloques (clic = saltar)
            Column {
                width: parent.width
                spacing: 6

                Item {
                    width: parent.width
                    height: 14

                    Row {
                        anchors.fill: parent
                        spacing: 3
                        Repeater {
                            model: 30
                            Rectangle {
                                required property int index
                                width: (parent.width - 29 * 3) / 30
                                height: 14
                                color: index < Math.round(Media.progress * 30) ? Theme.accent : Theme.track
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: mp.p?.canSeek ?? false
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: e => Media.seek(e.x / width)
                    }
                }

                Item {
                    width: parent.width
                    height: posText.implicitHeight
                    Text {
                        id: posText
                        text: Media.fmt(mp.p?.position ?? 0)
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                    }
                    Text {
                        anchors.right: parent.right
                        text: Media.fmt(mp.p?.length ?? 0)
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                    }
                }
            }

            // Controles
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Ctrl {
                    glyph: "⇄"
                    on: mp.p?.shuffle ?? false
                    enabledCtl: mp.p?.shuffleSupported ?? false
                    onClicked: Media.toggleShuffle()
                }
                Ctrl {
                    glyph: "|◀"
                    enabledCtl: mp.p?.canGoPrevious ?? false
                    onClicked: Media.previous()
                }
                Ctrl {
                    primary: true
                    glyph: mp.playing ? "❚❚" : "▶"
                    onClicked: Media.toggle()
                }
                Ctrl {
                    glyph: "▶|"
                    enabledCtl: mp.p?.canGoNext ?? false
                    onClicked: Media.next()
                }
                Ctrl {
                    readonly property int loop: mp.p?.loopState ?? MprisLoopState.None
                    glyph: loop === MprisLoopState.Track ? "↻1" : "↻"
                    on: loop !== MprisLoopState.None
                    enabledCtl: mp.p?.loopSupported ?? false
                    onClicked: Media.cycleLoop()
                }
            }

            // Visualizador decorativo
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.accentFaint
            }
            Item {
                width: parent.width
                height: 36

                Row {
                    anchors.bottom: parent.bottom
                    spacing: 3
                    Repeater {
                        model: 48
                        Rectangle {
                            id: vb
                            required property int index
                            readonly property real seed: (Math.sin(index * 12.9898) * 43758.5453) % 1
                            anchors.bottom: parent.bottom
                            width: (500 - 40 - 47 * 3) / 48
                            height: 6
                            color: index < 14 ? Theme.accent : Qt.alpha(Theme.accent, 0.35)

                            SequentialAnimation on height {
                                running: mp.playing && mp.visible
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 12 + Math.abs(vb.seed) * 24
                                    duration: 300 + Math.abs(vb.seed) * 500
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 6
                                    duration: 300 + Math.abs(vb.seed) * 500
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "ESPACIO play/pausa · ←→ pista · ESC cerrar"
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsXs
            }
        }
    }

    // Entrada: parpadeo + baja desde la barra
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
            NumberAnimation {
                target: panel
                property: "opacity"
                to: 1
                duration: 120
            }
        }
        NumberAnimation {
            target: shift
            property: "y"
            from: -16
            to: 0
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
}
