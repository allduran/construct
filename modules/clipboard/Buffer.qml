import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// BUFFER //: historial del portapapeles con filtros por tipo y vista previa.
PanelWindow {
    id: buf
    visible: ShellState.clipboardOpen

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-clipboard"
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
    property int kindTab: 0
    readonly property var kinds: ["TODO", "TEXTO", "CÓDIGO", "ENLACE", "COLOR", "IMAGEN"]

    function kindColor(k: string): color {
        return k === "CÓDIGO" ? Theme.cyan : k === "ENLACE" ? Theme.yellow : k === "COLOR" ? "#ff7ab0" : k === "IMAGEN" ? Theme.accent : Theme.text;
    }

    // Entradas filtradas por pestaña y texto (las fijadas ya vienen primero)
    readonly property var items: {
        const q = query.trim().toLowerCase();
        const k = kinds[kindTab];
        return Clipboard.entries.filter(e => (k === "TODO" || e.kind === k) && (!q || e.text.toLowerCase().includes(q)));
    }
    readonly property var current: items.length ? items[Math.min(sel, items.length - 1)] : null

    // Texto completo de la vista previa (cliphist lo carga aparte)
    readonly property string fullText: !current || current.kind === "IMAGEN" ? "" : (Clipboard.fullText || current.text)

    onCurrentChanged: Clipboard.load(current)
    onQueryChanged: sel = 0
    onKindTabChanged: sel = 0

    function count(k: string): int {
        return k === "TODO" ? Clipboard.entries.length : Clipboard.entries.filter(e => e.kind === k).length;
    }

    onVisibleChanged: {
        if (!visible)
            return;
        Clipboard.refresh();
        input.text = "";
        sel = 0;
        kindTab = 0;
        input.forceActiveFocus();
        openAnim.restart();
        title.glitch();
    }

    function close() {
        ShellState.clipboardOpen = false;
    }
    function move(d: int) {
        if (items.length)
            sel = (sel + d + items.length) % items.length;
    }

    // Cierra primero: así el foco vuelve a la ventana antes de pegar
    function use(andPaste: bool) {
        const e = current;
        if (!e)
            return;
        close();
        pending.fn = () => Clipboard.use(e, andPaste);
        pending.restart();
    }
    function openLink() {
        const url = current?.text.trim() ?? "";
        if (!url)
            return;
        close();
        Quickshell.execDetached(["xdg-open", url]);
    }

    Timer {
        id: pending
        property var fn: null
        interval: 150
        onTriggered: if (fn)
            fn()
    }

    // ── Botón de acción del pie de la vista previa ──
    component ActionBtn: CutPanel {
        id: ab
        required property string label
        property bool primary: false
        property bool danger: false
        signal clicked

        padding: 0
        implicitWidth: abText.implicitWidth + 36
        implicitHeight: 44
        cutTopRight: 0
        scanlines: false
        color: primary ? Theme.accent : abArea.containsMouse ? Qt.alpha(danger ? Theme.magenta : Theme.accent, 0.12) : "transparent"
        borderColor: primary ? Theme.accent : danger ? Qt.alpha(Theme.magenta, 0.5) : Theme.accentDim

        Text {
            id: abText
            anchors.centerIn: parent
            text: ab.label
            color: ab.primary ? Theme.accentFg : ab.danger ? "#ff5c9d" : Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: 12
            font.letterSpacing: 2
        }
        MouseArea {
            id: abArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ab.clicked()
        }
    }

    // ── Fondo ──
    MatrixRain {
        id: rain
        anchors.fill: parent
        opacity: 0.5
        running: Theme.rain && buf.visible
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.66)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: buf.close()
    }

    // ── Panel ──
    Item {
        id: panel
        width: 1320
        height: col.height
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.11
        transform: Translate {
            id: shift
        }

        MouseArea {
            anchors.fill: parent
        }

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
                    text: "BUFFER //"
                    color: Theme.accent
                    font.family: Theme.fontDisplay
                    font.pixelSize: 44
                    font.letterSpacing: 6
                }
                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    text: `${Clipboard.entries.length} ENTRADAS · ${Clipboard.pins.length} FIJADAS`
                    color: Theme.textDim
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fsSm
                    font.letterSpacing: Theme.tracking
                }
            }

            // Buscador
            CutPanel {
                width: parent.width
                height: 64
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
                        id: gt
                        anchors.verticalCenter: parent.verticalCenter
                        text: ">"
                        color: Theme.accent
                        font.family: Theme.fontMono
                        font.pixelSize: 24
                    }

                    TextInput {
                        id: input
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - gt.width - parent.spacing
                        color: Theme.textBright
                        selectionColor: Theme.accentDim
                        font.family: Theme.fontMono
                        font.pixelSize: 22
                        clip: true
                        onTextChanged: buf.query = text

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

                        Text {
                            visible: !input.text
                            anchors.verticalCenter: parent.verticalCenter
                            x: 20
                            text: "filtrar historial…"
                            color: Theme.textDim
                            font: input.font
                        }

                        Keys.onPressed: e => {
                            const ctrl = e.modifiers & Qt.ControlModifier;
                            const shift = e.modifiers & Qt.ShiftModifier;
                            if (e.key === Qt.Key_Escape)
                                buf.close();
                            else if (e.key === Qt.Key_Down)
                                buf.move(1);
                            else if (e.key === Qt.Key_Up)
                                buf.move(-1);
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                if (ctrl && buf.current?.kind === "ENLACE")
                                    buf.openLink();
                                else
                                    buf.use(!shift);
                            } else if (e.key === Qt.Key_Tab)
                                buf.kindTab = (buf.kindTab + 1) % buf.kinds.length;
                            else if (e.key === Qt.Key_Backtab)
                                buf.kindTab = (buf.kindTab + buf.kinds.length - 1) % buf.kinds.length;
                            else if (ctrl && e.key === Qt.Key_P)
                                Clipboard.togglePin(buf.current);
                            else if (e.key === Qt.Key_Delete)
                                Clipboard.remove(buf.current);
                            else
                                return;
                            e.accepted = true;
                        }
                    }
                }
            }

            // Filtros por tipo
            Row {
                spacing: 8
                Repeater {
                    model: buf.kinds
                    delegate: CutPanel {
                        id: kt
                        required property string modelData
                        required property int index
                        readonly property bool on: index === buf.kindTab

                        width: ktRow.implicitWidth + 32
                        height: 40
                        padding: 0
                        cutTopRight: 10
                        scanlines: false
                        color: on ? Theme.accent : Theme.surface
                        borderColor: on ? Theme.accent : Theme.accentDim

                        Row {
                            id: ktRow
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: kt.modelData
                                color: kt.on ? Theme.accentFg : Theme.textDim
                                font.family: Theme.fontDisplay
                                font.pixelSize: 12
                                font.letterSpacing: Theme.tracking
                            }
                            Text {
                                text: buf.count(kt.modelData)
                                color: kt.on ? Theme.accentFg : Theme.textDim
                                opacity: 0.7
                                font.family: Theme.fontDisplay
                                font.pixelSize: 12
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                buf.kindTab = kt.index;
                                input.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Lista + vista previa
            RowLayout {
                width: parent.width
                height: 620
                spacing: 14

                // ── Lista ──
                ListView {
                    id: list
                    Layout.preferredWidth: 520
                    Layout.fillHeight: true
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: buf.items
                    currentIndex: buf.sel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: CutPanel {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === buf.sel

                        width: ListView.view.width
                        height: 68
                        padding: 14
                        cutTopRight: 0
                        scanlines: false
                        color: selected ? Qt.alpha(Theme.accent, 0.12) : Theme.surface
                        borderColor: selected ? Theme.accent : Qt.alpha(Theme.textDim, 0.25)

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: buf.sel = row.index
                            onClicked: buf.use(true)
                        }

                        RowLayout {
                            width: parent.width
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            // Etiqueta de tipo (con muestra si es un color)
                            Rectangle {
                                Layout.preferredWidth: 84
                                Layout.preferredHeight: 26
                                color: "transparent"
                                border.color: buf.kindColor(row.modelData.kind)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle {
                                        visible: row.modelData.kind === "COLOR"
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 10
                                        height: 10
                                        color: row.modelData.kind === "COLOR" ? row.modelData.text.trim() : "transparent"
                                    }
                                    Text {
                                        text: row.modelData.kind
                                        color: buf.kindColor(row.modelData.kind)
                                        font.family: Theme.fontDisplay
                                        font.pixelSize: 11
                                        font.letterSpacing: 1.5
                                    }
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 3
                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    text: row.modelData.text
                                    color: Theme.textBright
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fsMd
                                }
                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: row.modelData.pinned ? "◆ fijada" : row.modelData.info
                                    color: row.modelData.pinned ? Theme.accent : Theme.textDim
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fsXs
                                }
                            }
                        }
                    }

                    Text {
                        visible: parent.count === 0
                        anchors.centerIn: parent
                        text: "buffer vacío_"
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsMd
                    }
                }

                // ── Vista previa ──
                CutPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: 0
                    cutTopRight: 22
                    cutBottomLeft: 22
                    color: Qt.alpha(Theme.bg, 0.94)
                    borderColor: Theme.accentDim

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        visible: buf.current !== null

                        // Cabecera
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            Layout.leftMargin: 18
                            Layout.rightMargin: 30
                            spacing: 12

                            Text {
                                text: buf.current?.kind ?? ""
                                color: buf.kindColor(buf.current?.kind ?? "")
                                font.family: Theme.fontDisplay
                                font.pixelSize: 12
                                font.letterSpacing: Theme.tracking
                            }
                            Text {
                                text: buf.current?.pinned ? "◆ FIJADA" : "ENTRADA #" + (buf.current?.id ?? "")
                                color: Theme.textDim
                                font.family: Theme.fontDisplay
                                font.pixelSize: 12
                                font.letterSpacing: Theme.tracking
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Text {
                                text: buf.current?.kind === "IMAGEN" ? buf.current.info : `${buf.fullText.split("\n").length} líneas · ${buf.fullText.length} car.`
                                color: Theme.textDim
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fsXs
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.accentFaint
                        }

                        // Contenido según el tipo
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: 22
                            clip: true

                            // Texto y código: con números de línea
                            Column {
                                visible: buf.current?.kind === "TEXTO" || buf.current?.kind === "CÓDIGO"
                                width: parent.width
                                Repeater {
                                    model: buf.fullText.split("\n").slice(0, 26)
                                    Row {
                                        required property string modelData
                                        required property int index
                                        spacing: 14
                                        Text {
                                            width: 40
                                            horizontalAlignment: Text.AlignRight
                                            text: index + 1
                                            color: Qt.alpha(Theme.textDim, 0.6)
                                            font.family: Theme.fontMono
                                            font.pixelSize: 15
                                            lineHeight: 1.5
                                        }
                                        Text {
                                            width: parent.parent.width - 54
                                            text: modelData || " "
                                            wrapMode: Text.WrapAnywhere
                                            color: Theme.textBright
                                            font.family: Theme.fontMono
                                            font.pixelSize: 15
                                            lineHeight: 1.5
                                        }
                                    }
                                }
                            }

                            // Color: muestra + valores
                            Column {
                                id: colorView
                                visible: buf.current?.kind === "COLOR"
                                width: parent.width
                                spacing: 18
                                readonly property color c: visible ? buf.current.text.trim() : "transparent"
                                readonly property var rows: [
                                    {
                                        k: "HEX",
                                        v: String(buf.current?.text ?? "").trim().toUpperCase()
                                    },
                                    {
                                        k: "RGB",
                                        v: [c.r, c.g, c.b].map(x => Math.round(x * 255)).join(", ")
                                    },
                                    {
                                        k: "QML",
                                        v: `Qt.rgba(${c.r.toFixed(2)}, ${c.g.toFixed(2)}, ${c.b.toFixed(2)})`
                                    }
                                ]

                                Rectangle {
                                    width: parent.width
                                    height: 260
                                    color: colorView.c
                                }
                                Row {
                                    width: parent.width
                                    spacing: 10
                                    Repeater {
                                        model: colorView.rows
                                        CutPanel {
                                            required property var modelData
                                            width: (colorView.width - 20) / 3
                                            padding: 12
                                            cutTopRight: 0
                                            scanlines: false
                                            color: "transparent"
                                            borderColor: Theme.accentFaint
                                            Column {
                                                spacing: 4
                                                Text {
                                                    text: modelData.k
                                                    color: Theme.textDim
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: Theme.fsXs
                                                    font.letterSpacing: 1.6
                                                }
                                                Text {
                                                    text: modelData.v
                                                    color: Theme.textBright
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 17
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Enlace: URL + partes
                            Column {
                                visible: buf.current?.kind === "ENLACE"
                                width: parent.width
                                spacing: 16
                                Text {
                                    text: "DESTINO"
                                    color: Theme.textDim
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fsSm
                                    font.letterSpacing: 2
                                }
                                Text {
                                    width: parent.width
                                    text: buf.current?.text ?? ""
                                    wrapMode: Text.WrapAnywhere
                                    color: Theme.yellow
                                    font.family: Theme.fontMono
                                    font.pixelSize: 26
                                }
                                Flow {
                                    width: parent.width
                                    spacing: 10
                                    Repeater {
                                        model: String(buf.current?.text ?? "").replace(/^https?:\/\//, "").split("/").filter(p => p)
                                        Rectangle {
                                            required property string modelData
                                            width: partText.implicitWidth + 20
                                            height: 30
                                            color: "transparent"
                                            border.color: Qt.alpha(Theme.yellow, 0.4)
                                            Text {
                                                id: partText
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: Theme.yellow
                                                font.family: Theme.fontMono
                                                font.pixelSize: Theme.fsSm
                                            }
                                        }
                                    }
                                }
                                Text {
                                    text: "ctrl + ↵ abre el enlace en el navegador"
                                    color: Theme.textDim
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                }
                            }

                            // Imagen: miniatura
                            Image {
                                visible: buf.current?.kind === "IMAGEN"
                                anchors.fill: parent
                                source: visible ? Clipboard.thumb(buf.current) : ""
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignLeft
                                verticalAlignment: Image.AlignTop
                                asynchronous: true
                                cache: false
                            }
                        }

                        // Acciones
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.accentFaint
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 14
                            spacing: 8

                            ActionBtn {
                                label: "↵ PEGAR"
                                primary: true
                                onClicked: buf.use(true)
                            }
                            ActionBtn {
                                label: "⇧↵ SOLO COPIAR"
                                onClicked: buf.use(false)
                            }
                            ActionBtn {
                                visible: buf.current?.kind !== "IMAGEN"
                                label: buf.current?.pinned ? "CTRL+P QUITAR" : "CTRL+P FIJAR"
                                onClicked: Clipboard.togglePin(buf.current)
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ActionBtn {
                                label: "SUPR BORRAR"
                                danger: true
                                onClicked: Clipboard.remove(buf.current)
                            }
                        }
                    }
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
                height: foot.implicitHeight
                Text {
                    id: foot
                    text: "↑↓ navegar · TAB tipo · ESC desconectar"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }
                Text {
                    anchors.right: parent.right
                    text: "◆ fijadas: no caducan · historial: cliphist"
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
