import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.common
import qs.components
import qs.services

// SEÑAL //: carrusel de fondos con filtro en vivo.
PanelWindow {
    id: sg
    visible: ShellState.wallpaperOpen

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-wallpicker"
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

    // ── Estado local (no toca el escritorio hasta APLICAR) ──
    property int sel: 0
    property int filter: 2
    property real intensity: 0.85

    readonly property var list: Wallpapers.list
    readonly property int n: list.length
    function at(d: int): var {
        return n ? list[((sel + d) % n + n) % n] : null;
    }
    readonly property var current: at(0)

    onVisibleChanged: {
        if (!visible)
            return;
        Wallpapers.refresh();
        sel = Math.max(0, list.findIndex(w => w.path === Wallpapers.current));
        filter = Wallpapers.filter;
        intensity = Wallpapers.intensity;
        keys.forceActiveFocus();
        openAnim.restart();
        title.glitch();
    }

    function close() {
        ShellState.wallpaperOpen = false;
    }
    function move(d: int) {
        if (n)
            sel = ((sel + d) % n + n) % n;
    }
    function apply() {
        if (!current)
            return;
        Wallpapers.apply(current.path, filter, intensity);
        close();
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            const d = parseInt(e.text);
            if (e.key === Qt.Key_Escape)
                sg.close();
            else if (e.key === Qt.Key_Right)
                sg.move(1);
            else if (e.key === Qt.Key_Left)
                sg.move(-1);
            else if (e.key === Qt.Key_Up)
                sg.intensity = Math.min(1, sg.intensity + 0.05);
            else if (e.key === Qt.Key_Down)
                sg.intensity = Math.max(0.05, sg.intensity - 0.05);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                sg.apply();
            else if (d >= 1 && d <= 4)
                sg.filter = d - 1;
            else
                return;
            e.accepted = true;
        }
    }

    // ── Tarjeta: imagen recortada en chaflán + borde ──
    component Card: Item {
        id: card
        property var wall: null
        property int filter: 0
        property real intensity: 0
        property bool big: false
        readonly property int cut: 22
        readonly property alias img: wi

        // Recorte de la imagen a la forma del chaflán
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        WallImage {
            id: wi
            anchors.fill: parent
            source: card.wall ? "file://" + card.wall.path : ""
            filter: card.filter
            intensity: card.intensity
        }

        Shape {
            id: mask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            ShapePath {
                fillColor: "white"
                strokeColor: "transparent"
                PathPolyline {
                    path: [Qt.point(0, 0), Qt.point(card.width - card.cut, 0), Qt.point(card.width, card.cut), Qt.point(card.width, card.height), Qt.point(card.cut, card.height), Qt.point(0, card.height - card.cut), Qt.point(0, 0)]
                }
            }
        }
    }

    // ── Fondo: el escritorio actual, oscurecido ──
    WallImage {
        anchors.fill: parent
        source: Wallpapers.current ? "file://" + Wallpapers.current : ""
        filter: Wallpapers.filter
        intensity: Wallpapers.intensity
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.78)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: sg.close()
    }

    // ── Contenido ──
    Item {
        id: content
        anchors.fill: parent
        transform: Translate {
            id: shift
        }

        readonly property real bigW: 960
        readonly property real bigH: 540
        readonly property real cx: width / 2
        readonly property real topY: height * 0.19

        // Cabecera
        Item {
            x: content.cx - content.bigW / 2
            y: content.topY - 90
            width: content.bigW
            height: title.height

            GlitchText {
                id: title
                text: "SEÑAL //"
                color: Theme.accent
                font.family: Theme.fontDisplay
                font.pixelSize: 40
                font.letterSpacing: 6
            }
            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: sg.n ? `${sg.sel + 1} / ${sg.n} · ~/Pictures/Wallpapers` : "~/Pictures/Wallpapers"
                color: Theme.textDim
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fsSm
                font.letterSpacing: Theme.tracking
            }
        }

        // Carpeta vacía
        Text {
            visible: sg.n === 0
            anchors.centerIn: parent
            text: "sin señal: no hay imágenes en ~/Pictures/Wallpapers_"
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsLg
        }

        // Laterales (sin filtro, atenuados). Clic: pasar al centro
        Repeater {
            model: sg.n > 1 ? [-1, 1] : []
            delegate: Item {
                id: side
                required property int modelData
                width: 360
                height: 202
                x: modelData < 0 ? content.cx - content.bigW / 2 - width - 40 : content.cx + content.bigW / 2 + 40
                y: content.topY + (content.bigH - height) / 2
                opacity: hov.hovered ? 0.75 : 0.45

                Card {
                    anchors.fill: parent
                    wall: sg.at(side.modelData)
                }
                CutPanel {
                    anchors.fill: parent
                    padding: 0
                    cutTopRight: 22
                    cutBottomLeft: 22
                    scanlines: false
                    color: "transparent"
                    borderColor: Theme.accentDim
                }
                HoverHandler {
                    id: hov
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: sg.move(side.modelData)
                }
            }
        }

        // Central: vista previa con el filtro elegido
        Item {
            id: center
            visible: sg.n > 0
            width: content.bigW
            height: content.bigH
            x: content.cx - width / 2
            y: content.topY

            Card {
                id: bigCard
                anchors.fill: parent
                wall: sg.current
                filter: sg.filter
                intensity: sg.intensity
                big: true
            }
            CutPanel {
                anchors.fill: parent
                padding: 0
                cutTopRight: 22
                cutBottomLeft: 22
                scanlines: false
                color: "transparent"
                borderColor: Theme.accent
            }
            Rectangle {
                visible: sg.current?.path === Wallpapers.current
                x: 14
                y: 14
                width: inUse.implicitWidth + 20
                height: 28
                color: Theme.accent
                Text {
                    id: inUse
                    anchors.centerIn: parent
                    text: "◆ EN USO"
                    color: Theme.accentFg
                    font.family: Theme.fontDisplay
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: sg.apply()
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Controles
        // Absorbe los clics sobre los controles (fuera de la Column para no crear un bucle)
        MouseArea {
            x: controls.x
            y: controls.y
            width: controls.width
            height: controls.height
        }

        Column {
            id: controls
            visible: sg.n > 0
            x: content.cx - content.bigW / 2
            y: content.topY + content.bigH + 40
            width: content.bigW
            spacing: 16

            Item {
                width: parent.width
                height: 44

                Row {
                    spacing: 6
                    Repeater {
                        model: Wallpapers.filterNames
                        delegate: CutPanel {
                            id: fc
                            required property string modelData
                            required property int index
                            readonly property bool on: index === sg.filter
                            width: fcRow.implicitWidth + 28
                            height: 44
                            padding: 0
                            cutTopRight: 10
                            scanlines: false
                            color: on ? Theme.accent : "transparent"
                            borderColor: on ? Theme.accent : Theme.accentDim
                            Row {
                                id: fcRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: fc.index + 1
                                    opacity: 0.6
                                    color: fc.on ? Theme.accentFg : Theme.accent
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: fc.modelData
                                    color: fc.on ? Theme.accentFg : Theme.textDim
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: 12
                                    font.letterSpacing: 2
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sg.filter = fc.index
                            }
                        }
                    }
                }

                CutPanel {
                    anchors.right: parent.right
                    width: applyText.implicitWidth + 40
                    height: 44
                    padding: 0
                    cutTopRight: 0
                    scanlines: false
                    color: Theme.accent
                    borderColor: Theme.accent
                    Text {
                        id: applyText
                        anchors.centerIn: parent
                        text: "↵ APLICAR"
                        color: Theme.accentFg
                        font.family: Theme.fontDisplay
                        font.pixelSize: 13
                        font.letterSpacing: 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sg.apply()
                    }
                }
            }

            // Intensidad
            Row {
                width: parent.width
                spacing: 14
                opacity: sg.filter === 0 ? 0.35 : 1

                Text {
                    width: 110
                    anchors.verticalCenter: parent.verticalCenter
                    text: "INTENSIDAD"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                    font.letterSpacing: 1.6
                }
                Item {
                    width: parent.width - 110 - 48 - parent.spacing * 2
                    height: 18
                    Row {
                        anchors.fill: parent
                        spacing: 3
                        Repeater {
                            model: 20
                            Rectangle {
                                required property int index
                                width: (parent.width - 19 * 3) / 20
                                height: 18
                                color: index < Math.round(sg.intensity * 20) ? Theme.accent : Theme.track
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: sg.filter !== 0
                        cursorShape: Qt.PointingHandCursor
                        function pick(x: real) {
                            sg.intensity = Math.max(0.05, Math.min(1, Math.ceil(x / width * 20) / 20));
                        }
                        onPressed: e => pick(e.x)
                        onPositionChanged: e => {
                            if (pressed)
                                pick(e.x);
                        }
                    }
                }
                Text {
                    width: 48
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(sg.intensity * 100) + "%"
                    color: Theme.textBright
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsMd
                }
            }

            // Pie
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.accentFaint
            }
            Item {
                width: parent.width
                height: info.implicitHeight
                Text {
                    id: info
                    textFormat: Text.StyledText
                    text: sg.current ? `<font color="${Theme.textBright}">${sg.current.name.replace(/</g, "&lt;")}</font> · ${Wallpapers.sizeText(sg.current.size)}` : ""
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }
                Text {
                    anchors.right: parent.right
                    text: "←→ fondo · 1–4 filtro · ↑↓ intensidad · ESC cerrar"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }
            }
        }
    }

    // Entrada
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
    }

    Scanlines {
        anchors.fill: parent
        lineOpacity: 0.22
    }
}
