import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.common
import qs.components
import qs.services

// GLIFOS //: selector de emojis con búsqueda, frecuentes y grupos.
PanelWindow {
    id: gl
    visible: ShellState.emojiOpen

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-emoji"
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

    readonly property string emojiFont: "Noto Color Emoji"
    readonly property int cols: 10

    // ── Estado ──
    property string query: ""
    property int tab: 0
    property int sel: 0

    // Con texto: resultados de búsqueda; sin texto: el grupo de la pestaña
    readonly property bool searching: query.trim() !== ""
    readonly property var items: searching ? Emoji.search(query) : Emoji.inGroup(Emoji.groups[tab][0])
    readonly property var current: items.length ? items[Math.min(sel, items.length - 1)] : null

    onQueryChanged: sel = 0
    onTabChanged: sel = 0

    onVisibleChanged: {
        if (!visible)
            return;
        input.text = "";
        tab = 0;
        sel = 0;
        input.forceActiveFocus();
        openAnim.restart();
        title.glitch();
    }

    function close() {
        ShellState.emojiOpen = false;
    }

    // Emoji.pick ya espera 150 ms a que vuelva el foco antes de pegar
    function pick(e: string, andType: bool) {
        if (!e)
            return;
        close();
        Emoji.pick(e, andType);
    }

    function move(d: int) {
        if (!items.length)
            return;
        sel = Math.max(0, Math.min(items.length - 1, sel + d));
    }

    // "🔥" → "U+1F525"
    function codepoints(e: string): string {
        return Array.from(e).map(c => "U+" + c.codePointAt(0).toString(16).toUpperCase()).join(" ");
    }

    // ── Fondo ──
    MatrixRain {
        id: rain
        anchors.fill: parent
        opacity: 0.5
        running: Theme.rain && gl.visible
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.66)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: gl.close()
    }

    // ── Panel ──
    CutPanel {
        id: panel
        width: 760
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.11
        padding: 24
        cutTopRight: 24
        cutBottomLeft: 24
        color: Qt.alpha(Theme.bg, 0.94)
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
            spacing: 14

            // Cabecera
            Item {
                width: parent.width
                height: title.height
                GlitchText {
                    id: title
                    text: "GLIFOS //"
                    color: Theme.accent
                    font.family: Theme.fontDisplay
                    font.pixelSize: 36
                    font.letterSpacing: 6
                }
                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    text: gl.searching ? `${gl.items.length} COINCIDENCIAS` : `${Emoji.all.length} GLIFOS`
                    color: Theme.textDim
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fsSm
                    font.letterSpacing: Theme.tracking
                }
            }

            // Buscador
            CutPanel {
                width: parent.width
                height: 56
                padding: 18
                cutTopRight: 16
                cutBottomLeft: 16
                scanlines: false
                color: Theme.bg
                borderColor: Theme.accent

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 12

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
                        width: parent.width - gt.width - parent.spacing
                        color: Theme.textBright
                        selectionColor: Theme.accentDim
                        font.family: Theme.fontMono
                        font.pixelSize: 18
                        clip: true
                        onTextChanged: gl.query = text

                        cursorDelegate: Rectangle {
                            id: caret
                            width: 10
                            color: Theme.accent
                            Timer {
                                interval: 530
                                running: input.activeFocus
                                repeat: true
                                onTriggered: caret.opacity = caret.opacity > 0 ? 0 : 1
                            }
                        }

                        Text {
                            visible: !input.text
                            anchors.verticalCenter: parent.verticalCenter
                            x: 16
                            text: "buscar glifo… fuego, risa, gato"
                            color: Theme.textDim
                            font: input.font
                        }

                        Keys.onPressed: e => {
                            const n = Emoji.groups.length;
                            if (e.key === Qt.Key_Escape)
                                gl.close();
                            else if (e.key === Qt.Key_Right)
                                gl.move(1);
                            else if (e.key === Qt.Key_Left)
                                gl.move(-1);
                            else if (e.key === Qt.Key_Down)
                                gl.move(gl.cols);
                            else if (e.key === Qt.Key_Up)
                                gl.move(-gl.cols);
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                                gl.pick(gl.current?.e ?? "", !(e.modifiers & Qt.ShiftModifier));
                            else if (e.key === Qt.Key_Tab && !gl.searching)
                                gl.tab = (gl.tab + 1) % n;
                            else if (e.key === Qt.Key_Backtab && !gl.searching)
                                gl.tab = (gl.tab + n - 1) % n;
                            else
                                return;
                            e.accepted = true;
                        }
                    }
                }
            }

            // Frecuentes (los mismos 8 de la retícula)
            Column {
                visible: !gl.searching
                width: parent.width
                spacing: 8

                Text {
                    text: "FRECUENTES"
                    color: Theme.textDim
                    font.family: Theme.fontDisplay
                    font.pixelSize: 12
                    font.letterSpacing: Theme.tracking
                }
                Row {
                    spacing: 6
                    Repeater {
                        model: Emoji.wheel
                        delegate: Rectangle {
                            id: fq
                            required property string modelData
                            width: (panel.width - panel.padding * 2 - 7 * 6) / 8
                            height: 52
                            color: fqHover.hovered ? Qt.alpha(Theme.accent, 0.15) : "transparent"
                            border.color: fqHover.hovered ? Theme.accent : Theme.accentDim

                            Text {
                                anchors.centerIn: parent
                                text: fq.modelData
                                font.family: gl.emojiFont
                                font.pixelSize: 28
                            }
                            HoverHandler {
                                id: fqHover
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: gl.pick(fq.modelData, true)
                            }
                        }
                    }
                }
            }

            // Pestañas de grupo
            Flow {
                visible: !gl.searching
                width: parent.width
                spacing: 6

                Repeater {
                    model: Emoji.groups
                    delegate: CutPanel {
                        id: gt2
                        required property var modelData
                        required property int index
                        readonly property bool on: index === gl.tab

                        width: gtText.implicitWidth + 28
                        height: 40
                        padding: 0
                        cutTopRight: 10
                        scanlines: false
                        color: on ? Theme.accent : "transparent"
                        borderColor: on ? Theme.accent : Theme.accentDim

                        Text {
                            id: gtText
                            anchors.centerIn: parent
                            text: gt2.modelData[1]
                            color: gt2.on ? Theme.accentFg : Theme.textDim
                            font.family: Theme.fontDisplay
                            font.pixelSize: 12
                            font.letterSpacing: 2
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                gl.tab = gt2.index;
                                input.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Cuadrícula
            GridView {
                id: grid
                width: parent.width
                height: gl.searching ? 5 * cellHeight + 124 : 4 * cellHeight
                cellWidth: width / gl.cols
                cellHeight: 70
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: gl.items
                currentIndex: gl.sel
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === gl.sel

                    width: grid.cellWidth
                    height: grid.cellHeight

                    CutPanel {
                        anchors.fill: parent
                        anchors.margins: 3
                        padding: 0
                        cutTopRight: cell.selected ? 10 : 0
                        scanlines: false
                        color: cell.selected ? Qt.alpha(Theme.accent, 0.18) : Qt.alpha(Theme.textDim, 0.06)
                        borderColor: cell.selected ? Theme.accent : Qt.alpha(Theme.textDim, 0.18)

                        Text {
                            anchors.centerIn: parent
                            text: cell.modelData.e
                            font.family: gl.emojiFont
                            font.pixelSize: 32
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: gl.sel = cell.index
                        onClicked: gl.pick(cell.modelData.e, true)
                    }
                }

                Text {
                    visible: parent.count === 0
                    anchors.centerIn: parent
                    text: "ningún glifo coincide_"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsMd
                }
            }

            // Seleccionado + acciones
            CutPanel {
                width: parent.width
                height: 72
                padding: 14
                cutTopRight: 0
                scanlines: false
                color: Qt.alpha(Theme.accent, 0.12)
                borderColor: Theme.accent

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 16

                    Text {
                        id: bigEmoji
                        anchors.verticalCenter: parent.verticalCenter
                        text: gl.current?.e ?? ""
                        font.family: gl.emojiFont
                        font.pixelSize: 40
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - bigEmoji.width - hints.width - parent.spacing * 2
                        spacing: 3
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: gl.current?.n ?? ""
                            color: Theme.textBright
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                        }
                        Text {
                            text: gl.current ? gl.codepoints(gl.current.e) : ""
                            color: Theme.textDim
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fsSm
                        }
                    }
                    Text {
                        id: hints
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↵ ESCRIBIR · ⇧↵ COPIAR"
                        color: Theme.accent
                        font.family: Theme.fontDisplay
                        font.pixelSize: 12
                        font.letterSpacing: 2
                    }
                }
            }

            Text {
                text: "←↑↓→ navegar · TAB grupo · ESC desconectar"
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSm
            }
        }
    }

    // Entrada
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
            to: 0.5
            duration: 400
        }
    }

    Scanlines {
        anchors.fill: parent
    }
}
