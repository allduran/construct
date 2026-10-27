import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.common
import qs.components
import qs.services

// Launcher "JACK IN //": buscador de apps a pantalla completa sobre la lluvia.
PanelWindow {
    id: launcher
    visible: ShellState.launcherOpen

    // Se abre en el monitor que tiene el foco
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-launcher"
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

    // ── Estado ──
    property string query: ""
    property int sel: 0
    property int tab: 0                       // índice en 'tabs'
    readonly property var tabs: ["APPS", "COMANDOS", "CALC", "WEB"]
    readonly property int maxVisible: 7

    // Empezar por "=" lleva a CALC sin cambiar de pestaña
    readonly property bool calcMode: tab === 2 || query.startsWith("=")
    // "!g texto" desde cualquier pestaña lleva a WEB
    readonly property bool webMode: !calcMode && (tab === 3 || /^!\S+\s/.test(query))

    // Todo se normaliza a { name, sub, icon, abbr, hint, run }:
    // la lista pinta igual apps, comandos y resultados
    readonly property var items: {
        if (calcMode) {
            const r = Calc.evaluate(query);
            return r === "" ? [] : [
                {
                    name: r,
                    sub: query.replace(/^=/, "").trim(),
                    icon: "",
                    abbr: "=",
                    hint: "CALC",
                    run: () => Quickshell.execDetached(["wl-copy", r])
                }
            ];
        }
        if (webMode)
            return Web.results(query);
        if (tab === 1)
            return Commands.search(query).map(c => ({
                        name: c.name,
                        sub: c.sub,
                        icon: "",
                        abbr: c.abbr,
                        hint: c.hint,
                        run: c.run
                    }));
        return Apps.search(query).map(a => ({
                    name: a.name,
                    sub: a.genericName || a.comment || "",
                    icon: Apps.icon(a),
                    abbr: "",
                    hint: "APP",
                    run: () => Apps.launch(a)
                }));
    }
    readonly property var current: items[sel] ?? null

    onQueryChanged: sel = 0
    onTabChanged: sel = 0

    // 1793043656000 → "14 min"
    function ago(t: real): string {
        const m = Math.floor((Date.now() - t) / 60000);
        return m < 1 ? "ahora" : m < 60 ? `${m} min` : m < 1440 ? `${Math.floor(m / 60)} h` : `${Math.floor(m / 1440)} d`;
    }
    onVisibleChanged: {
        if (!visible)
            return;
        input.text = "";
        sel = 0;
        tab = 0;
        input.forceActiveFocus();
        openAnim.restart();
        title.glitch();
    }

    function close() {
        ShellState.launcherOpen = false;
    }
    function move(d: int) {
        if (items.length)
            sel = (sel + d + items.length) % items.length;
    }

    // Cierra primero y lanza después: la app no hereda el foco del overlay
    function runAfterClose(fn) {
        pending.fn = fn;
        close();
        pending.restart();
    }
    function activate(item) {
        if (item)
            runAfterClose(item.run);
    }

    Timer {
        id: pending
        property var fn: null
        interval: 150
        onTriggered: if (fn)
            fn()
    }

    // Entrada: parpadeo de monitor + subida + lluvia que aparece
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
            target: panelShift
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

    // ── Fondo: lluvia + velo oscuro. Clic fuera del panel = cerrar ──
    MatrixRain {
        id: rain
        anchors.fill: parent
        opacity: 0.6
        running: Theme.rain && launcher.visible
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.55)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: launcher.close()
    }

    // ── Panel central ──
    Item {
        id: panel
        width: 920
        height: col.height
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.16
        transform: Translate {
            id: panelShift
        }

        MouseArea {
            anchors.fill: parent
        }   // los clics dentro del panel no cierran

        Column {
            id: col
            width: parent.width
            spacing: 14

            // Cabecera
            Item {
                width: parent.width
                height: title.height

                GlitchText {
                    id: title
                    text: "JACK IN //"
                    color: Theme.accent
                    font.family: Theme.fontDisplay
                    font.pixelSize: 44
                    font.letterSpacing: 6
                }
                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    text: `${launcher.items.length} COINCIDENCIAS`
                    color: Theme.textDim
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fsSm
                    font.letterSpacing: Theme.tracking
                }
            }

            // Campo de búsqueda
            CutPanel {
                width: parent.width
                height: 72
                padding: 22
                cutTopRight: 20
                cutBottomLeft: 20
                color: Qt.alpha(Theme.bg, 0.94)
                borderColor: Theme.accent

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 14

                    Text {
                        id: prompt
                        anchors.verticalCenter: parent.verticalCenter
                        text: ">"
                        color: Theme.accent
                        font.family: Theme.fontMono
                        font.pixelSize: 26
                    }

                    TextInput {
                        id: input
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - prompt.width - escHint.width - parent.spacing * 2
                        color: Theme.textBright
                        selectionColor: Theme.accentDim
                        font.family: Theme.fontMono
                        font.pixelSize: 26
                        clip: true

                        onTextChanged: launcher.query = text

                        // Cursor de bloque parpadeante
                        cursorDelegate: Rectangle {
                            id: caret
                            width: 13
                            color: Theme.accent
                            Timer {
                                interval: 530
                                running: input.activeFocus
                                repeat: true
                                onTriggered: caret.opacity = caret.opacity > 0 ? 0 : 1
                            }
                        }

                        // Texto de ayuda cuando está vacío
                        Text {
                            visible: !input.text
                            anchors.verticalCenter: parent.verticalCenter
                            x: 20
                            text: ["buscar programa…", "buscar comando…", "2^10, sqrt(2)*pi…", "!yt lofi, archlinux.org…"][launcher.tab]
                            color: Theme.textDim
                            font: input.font
                        }

                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape)
                                launcher.close();
                            else if (e.key === Qt.Key_Down)
                                launcher.move(1);
                            else if (e.key === Qt.Key_Up)
                                launcher.move(-1);
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                                launcher.activate(launcher.current);
                            else if (e.key === Qt.Key_Tab)
                                launcher.tab = (launcher.tab + 1) % launcher.tabs.length;
                            else if (e.key === Qt.Key_Backtab)
                                launcher.tab = (launcher.tab + launcher.tabs.length - 1) % launcher.tabs.length;
                            else
                                return;
                            e.accepted = true;
                        }
                    }

                    Text {
                        id: escHint
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ESC"
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                        font.letterSpacing: 2
                    }
                }
            }

            // Pestañas
            Row {
                spacing: 8

                Repeater {
                    model: launcher.tabs

                    delegate: CutPanel {
                        id: tabChip
                        required property string modelData
                        required property int index
                        // Con "=" se marca CALC aunque la pestaña sea otra
                        readonly property bool on: index === (launcher.calcMode ? 2 : launcher.webMode ? 3 : launcher.tab)

                        width: tabLabel.implicitWidth + 36
                        height: 44
                        padding: 0
                        cutTopRight: 10
                        scanlines: false
                        color: on ? Theme.accent : Theme.surface
                        borderColor: on ? Theme.accent : Theme.accentDim

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: tabChip.modelData
                            color: tabChip.on ? Theme.accentFg : Theme.textDim
                            font.family: Theme.fontDisplay
                            font.pixelSize: 13
                            font.letterSpacing: Theme.tracking
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                launcher.tab = tabChip.index;
                                input.forceActiveFocus();   // seguir escribiendo tras el clic
                            }
                        }
                    }
                }
            }

            // Resultados
            ListView {
                id: list
                width: parent.width
                height: Math.min(count, launcher.maxVisible) * (68 + spacing)
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: launcher.items
                currentIndex: launcher.sel
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: CutPanel {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === launcher.sel

                    width: list.width
                    height: 68
                    padding: 12
                    cutTopRight: 0
                    scanlines: false
                    color: selected ? Qt.alpha(Theme.accent, 0.12) : Theme.surface
                    borderColor: selected ? Theme.accent : Qt.alpha(Theme.textDim, 0.25)

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: launcher.sel = row.index
                        onClicked: launcher.activate(row.modelData)
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 18

                        // Caja: icono de la app, o abreviatura para comandos y cálculos
                        CutPanel {
                            width: 52
                            height: 44
                            padding: 0
                            cutTopRight: Theme.cutSmall
                            cutBottomLeft: Theme.cutSmall
                            borderWidth: 0
                            scanlines: false
                            color: row.selected ? Theme.accent : Qt.alpha(Theme.textDim, 0.18)

                            IconImage {
                                visible: row.modelData.icon !== ""
                                anchors.centerIn: parent
                                implicitSize: 26
                                source: row.modelData.icon
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: row.selected ? Theme.accentFg : Theme.accent
                                }
                            }
                            Text {
                                visible: row.modelData.icon === ""
                                anchors.centerIn: parent
                                text: row.modelData.abbr
                                color: row.selected ? Theme.accentFg : Theme.accent
                                font.family: Theme.fontDisplay
                                font.pixelSize: 15
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                width: list.width - 52 - 18 - 160
                                elide: Text.ElideRight
                                text: row.modelData.name
                                color: Theme.textBright
                                font.family: Theme.fontMono
                                font.pixelSize: launcher.calcMode ? 24 : 17
                            }
                            Text {
                                width: list.width - 52 - 18 - 160
                                elide: Text.ElideRight
                                visible: text !== ""
                                text: row.modelData.sub
                                color: Theme.textDim
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fsSm
                            }
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.selected ? (launcher.calcMode ? "↵ COPIAR" : launcher.webMode ? "↵ ABRIR" : "↵ EJECUTAR") : row.modelData.hint
                        color: row.selected ? Theme.accent : Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                        font.letterSpacing: 1.6
                    }
                }
            }

            // Sin resultados
            Text {
                visible: launcher.items.length === 0
                text: launcher.calcMode ? "expresión no válida_" : "sin coincidencias en la matriz_"
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsMd
            }

            // Pie con atajos
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.accentFaint
            }
            Item {
                width: parent.width
                height: keysHint.implicitHeight

                Text {
                    id: keysHint
                    text: "↑↓ navegar · ↵ ejecutar · TAB pestaña · ESC desconectar"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }
                Text {
                    anchors.right: parent.right
                    text: "=2^10 → calc · !yt texto → web"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }
            }
        }
    }

    // ── Recientes: a la derecha del panel, solo en APPS ──
    Column {
        visible: launcher.tab === 0 && !launcher.calcMode && !launcher.webMode && recentRep.count > 0
        x: panel.x + panel.width + 40
        y: panel.y + 130
        width: 280
        spacing: 8

        Text {
            text: "RECIENTES"
            color: Theme.accent
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fsSm
            font.letterSpacing: Theme.tracking
        }

        Repeater {
            id: recentRep
            // Se recalcula al abrir y cada vez que lanzas una app
            model: launcher.visible ? Apps.recent(4) : []

            delegate: CutPanel {
                id: rc
                required property var modelData

                width: 280
                padding: 10
                cutTopRight: 0
                scanlines: false
                borderColor: Theme.accentFaint

                Item {
                    // implicit*: CutPanel calcula su alto con el de sus hijos
                    implicitWidth: 260
                    implicitHeight: rcName.implicitHeight

                    Text {
                        id: rcName
                        width: parent.width - rcAgo.width - 10
                        elide: Text.ElideRight
                        text: rc.modelData.app.name
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsMd
                    }
                    Text {
                        id: rcAgo
                        anchors.right: parent.right
                        text: launcher.ago(rc.modelData.last)
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSm
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launcher.runAfterClose(() => Apps.launch(rc.modelData.app))
                }
            }
        }
    }

    // CRT sobre toda la pantalla
    Scanlines {
        anchors.fill: parent
    }
}
