import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.common
import qs.components
import qs.services

// ENFOQUE //: selector de zona, ventana o pantalla para capturar o grabar (uno por monitor).
PanelWindow {
    id: sel
    required property var modelData
    screen: modelData
    visible: Capture.selecting

    WlrLayershell.namespace: "construct-focus"
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

    // ── Modos ──
    readonly property var modes: [
        {
            key: "Z",
            label: "ZONA",
            rec: false
        },
        {
            key: "V",
            label: "VENTANA",
            rec: false
        },
        {
            key: "P",
            label: "PANTALLA",
            rec: false
        },
        {
            key: "R",
            label: "GRABAR",
            rec: true
        },
    ]
    property int mode: 0
    property bool audio: false
    readonly property bool isRec: modes[mode].rec
    readonly property color tone: isRec ? Theme.magenta : Theme.accent

    // Lupa: si ves en ella el oscurecido del propio selector, ponla a false
    property bool loupe: true

    // ── Selección ──
    property real x1: 0
    property real y1: 0
    property real x2: 0
    property real y2: 0
    property bool dragging: false
    property var hovered: null
    property real mx: width / 2
    property real my: height / 2

    readonly property real sx: Math.min(x1, x2)
    readonly property real sy: Math.min(y1, y2)
    readonly property real sw: Math.abs(x2 - x1)
    readonly property real sh: Math.abs(y2 - y1)
    readonly property bool hasSel: sw > 4 && sh > 4

    // Zona iluminada según el modo
    readonly property var focusRect: {
        const label = modes[mode].label;
        if (label === "PANTALLA")
            return {
                x: 0,
                y: 0,
                w: width,
                h: height
            };
        if (label === "VENTANA")
            return hovered;
        if (hasSel)
            return {
                x: sx,
                y: sy,
                w: sw,
                h: sh
            };
        return hovered;
    }
    readonly property real fx: focusRect?.x ?? 0
    readonly property real fy: focusRect?.y ?? 0
    readonly property real fw: focusRect?.w ?? 0
    readonly property real fh: focusRect?.h ?? 0

    onVisibleChanged: {
        if (!visible)
            return;
        dragging = false;
        hovered = null;
        x1 = y1 = x2 = y2 = 0;
        audio = Capture.pendingMode === "record-area-sound";
        mode = Capture.pendingMode.startsWith("record") ? 3 : 0;
        keys.forceActiveFocus();
    }

    // Ventanas visibles en este monitor, en coordenadas locales (de ancient)
    function windowsHere(): var {
        const mon = Hyprland.monitorFor(sel.screen);
        if (!mon?.activeWorkspace)
            return [];
        return Hyprland.toplevels.values.filter(t => t.workspace?.id === mon.activeWorkspace.id && t.lastIpcObject.at).map(t => ({
                    x: t.lastIpcObject.at[0] - sel.screen.x,
                    y: t.lastIpcObject.at[1] - sel.screen.y,
                    w: t.lastIpcObject.size[0],
                    h: t.lastIpcObject.size[1]
                }));
    }
    // La más pequeña que contiene el punto (la de encima si se solapan)
    function windowAt(px: real, py: real): var {
        let best = null;
        for (const w of windowsHere())
            if (px >= w.x && px <= w.x + w.w && py >= w.y && py <= w.y + w.h)
                if (!best || w.w * w.h < best.w * best.h)
                    best = w;
        return best;
    }

    // Confirma la zona iluminada
    function confirm(): void {
        if (fw < 4 || fh < 4)
            return;
        Capture.pendingMode = !isRec ? "area" : audio ? "record-area-sound" : "record-area";
        Capture.finishSelect(Math.round(fx + sel.screen.x), Math.round(fy + sel.screen.y), Math.round(fw), Math.round(fh));
    }

    // ── Teclado ──
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            const k = e.text.toUpperCase();
            const i = sel.modes.findIndex(m => m.key === k);
            if (e.key === Qt.Key_Escape)
                Capture.cancelSelect();
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                sel.confirm();
            else if (e.key === Qt.Key_Space) {
                sel.mode = sel.isRec ? 3 : 2;
                x1 = y1 = x2 = y2 = 0;
                sel.confirmFull();
            } else if (i >= 0) {
                sel.mode = i;
                x1 = y1 = x2 = y2 = 0;
            } else if (k === "A" && sel.isRec)
                sel.audio = !sel.audio;
            else
                return;
            e.accepted = true;
        }
    }
    // Espacio: pantalla completa (en GRABAR, graba la pantalla con la zona = monitor)
    function confirmFull(): void {
        x1 = 0;
        y1 = 0;
        x2 = width;
        y2 = height;
        Qt.callLater(confirm);
    }

    // ── Ratón ──
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor

        onPressed: e => {
            if (sel.modes[sel.mode].label !== "ZONA" && !sel.isRec)
                return;
            sel.dragging = true;
            sel.x1 = sel.x2 = e.x;
            sel.y1 = sel.y2 = e.y;
        }
        onPositionChanged: e => {
            sel.mx = e.x;
            sel.my = e.y;
            if (sel.dragging) {
                sel.x2 = e.x;
                sel.y2 = e.y;
            } else
                sel.hovered = sel.windowAt(e.x, e.y);
        }
        onReleased: {
            if (!sel.dragging) {
                sel.confirm();
                return;
            }    // VENTANA / PANTALLA: clic = capturar
            sel.dragging = false;
            if (sel.hasSel)
                sel.confirm();
            else {
                sel.x1 = sel.y1 = sel.x2 = sel.y2 = 0;
                sel.confirm();
            }   // clic sin arrastrar = ventana
        }
    }

    // ── Oscurecido alrededor de la zona ──
    readonly property color dim: Qt.alpha(Theme.bg, 0.72)
    Rectangle {
        x: 0
        y: 0
        width: sel.width
        height: sel.fy
        color: sel.dim
    }
    Rectangle {
        x: 0
        y: sel.fy + sel.fh
        width: sel.width
        height: sel.height - sel.fy - sel.fh
        color: sel.dim
    }
    Rectangle {
        x: 0
        y: sel.fy
        width: sel.fx
        height: sel.fh
        color: sel.dim
    }
    Rectangle {
        x: sel.fx + sel.fw
        y: sel.fy
        width: sel.width - sel.fx - sel.fw
        height: sel.fh
        color: sel.dim
    }

    // Cruz del cursor de lado a lado
    Rectangle {
        x: 0
        y: sel.my
        width: sel.width
        height: 1
        color: Qt.alpha(sel.tone, 0.22)
    }
    Rectangle {
        x: sel.mx
        y: 0
        width: 1
        height: sel.height
        color: Qt.alpha(sel.tone, 0.22)
    }

    // ── Marco de la zona ──
    component Bracket: Item {
        property bool flipX: false
        property bool flipY: false
        width: 34
        height: 34
        Rectangle {
            width: 34
            height: 3
            y: parent.flipY ? 31 : 0
            color: sel.tone
        }
        Rectangle {
            width: 3
            height: 34
            x: parent.flipX ? 31 : 0
            color: sel.tone
        }
    }

    Item {
        visible: sel.fw > 0
        x: sel.fx
        y: sel.fy
        width: sel.fw
        height: sel.fh

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.alpha(sel.tone, 0.5)
        }
        Bracket {
            x: -3
            y: -3
        }
        Bracket {
            x: parent.width - 31
            y: -3
            flipX: true
        }
        Bracket {
            x: -3
            y: parent.height - 31
            flipY: true
        }
        Bracket {
            x: parent.width - 31
            y: parent.height - 31
            flipX: true
            flipY: true
        }

        // Cruz central
        Rectangle {
            anchors.centerIn: parent
            width: 22
            height: 2
            color: Qt.alpha(sel.tone, 0.5)
        }
        Rectangle {
            anchors.centerIn: parent
            width: 2
            height: 22
            color: Qt.alpha(sel.tone, 0.5)
        }

        // Etiqueta de modo (dentro si la zona toca el borde superior)
        Row {
            x: -1
            y: parent.y > 40 ? -34 : 8
            Rectangle {
                width: tag.implicitWidth + 20
                height: 28
                color: sel.tone
                Text {
                    id: tag
                    anchors.centerIn: parent
                    text: sel.isRec ? "GRABACIÓN" : "CAPTURA"
                    color: Theme.accentFg
                    font.family: Theme.fontDisplay
                    font.pixelSize: 12
                    font.letterSpacing: 2
                }
            }
            Rectangle {
                visible: sel.isRec
                width: recTag.implicitWidth + 20
                height: 28
                color: "transparent"
                border.color: sel.tone
                Text {
                    id: recTag
                    anchors.centerIn: parent
                    text: sel.audio ? "● REC + AUDIO" : "● REC"
                    color: sel.tone
                    font.family: Theme.fontDisplay
                    font.pixelSize: 12
                    font.letterSpacing: 2
                    SequentialAnimation on opacity {
                        running: sel.isRec && sel.visible
                        loops: Animation.Infinite
                        PropertyAction {
                            value: 1
                        }
                        PauseAnimation {
                            duration: 500
                        }
                        PropertyAction {
                            value: 0.25
                        }
                        PauseAnimation {
                            duration: 500
                        }
                    }
                }
            }
        }

        // Coordenadas y tamaño
        Rectangle {
            readonly property bool inside: sel.fy + sel.fh + 40 > sel.height
            anchors.right: parent.right
            anchors.rightMargin: inside ? 8 : -1
            y: inside ? parent.height - height - 8 : parent.height + 6
            width: coords.implicitWidth + 20
            height: 28
            color: Qt.alpha(Theme.bg, 0.94)
            border.color: Qt.alpha(sel.tone, 0.5)
            Text {
                id: coords
                anchors.centerIn: parent
                textFormat: Text.StyledText
                text: `x ${Math.round(sel.fx)} · y ${Math.round(sel.fy)} · <font color="${sel.tone}">${Math.round(sel.fw)} × ${Math.round(sel.fh)}</font>`
                color: Theme.textBright
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSm
            }
        }
    }

    // ── Lupa ×8 junto al cursor ──
    Rectangle {
        id: loupeBox
        visible: sel.loupe && (sel.modes[sel.mode].label === "ZONA" || sel.isRec)
        readonly property int size: 132
        readonly property int zoom: 8
        width: size
        height: size
        x: Math.min(sel.width - size - 8, sel.mx + 18)
        y: Math.min(sel.height - size - 8, sel.my + 18)
        color: Theme.bg
        border.color: sel.tone
        clip: true

        // Foto fija de la pantalla al abrir, ampliada y centrada en el cursor
        ScreencopyView {
            captureSource: sel.visible && loupeBox.visible ? sel.screen : null
            live: false
            width: sel.width
            height: sel.height
            transformOrigin: Item.TopLeft
            scale: loupeBox.zoom
            x: loupeBox.size / 2 - sel.mx * loupeBox.zoom
            y: loupeBox.size / 2 - sel.my * loupeBox.zoom
            smooth: false        // píxeles nítidos, sin suavizado
        }
        // Rejilla de píxeles
        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.strokeStyle = Qt.alpha(Theme.accent, 0.18).toString();
                for (let i = 0; i <= width; i += loupeBox.zoom) {
                    ctx.beginPath();
                    ctx.moveTo(i, 0);
                    ctx.lineTo(i, height);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(0, i);
                    ctx.lineTo(width, i);
                    ctx.stroke();
                }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: loupeBox.zoom + 4
            height: width
            color: "transparent"
            border.color: sel.tone
            border.width: 2
        }
        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            text: "×" + loupeBox.zoom
            color: sel.tone
            font.family: Theme.fontMono
            font.pixelSize: 10
        }
    }

    // ── Barra de modos ──
    CutPanel {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 96
        padding: 12
        cutTopRight: 16
        cutBottomLeft: 16
        color: Qt.alpha(Theme.bg, 0.95)
        borderColor: Qt.alpha(sel.tone, 0.5)

        Row {
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ENFOQUE //"
                color: sel.tone
                font.family: Theme.fontDisplay
                font.pixelSize: 22
                font.letterSpacing: 5
            }

            Repeater {
                model: sel.modes
                delegate: CutPanel {
                    id: chip
                    required property var modelData
                    required property int index
                    readonly property bool on: index === sel.mode
                    readonly property color t: modelData.rec ? Theme.magenta : Theme.accent

                    anchors.verticalCenter: parent.verticalCenter
                    width: chipRow.implicitWidth + 28
                    height: 44
                    padding: 0
                    cutTopRight: 10
                    scanlines: false
                    color: on ? t : "transparent"
                    borderColor: on ? t : Qt.alpha(t, 0.4)

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: chip.modelData.key
                            opacity: 0.6
                            color: chip.on ? Theme.accentFg : chip.t
                            font.family: Theme.fontDisplay
                            font.pixelSize: 12
                        }
                        Text {
                            text: chip.modelData.label
                            color: chip.on ? Theme.accentFg : Theme.textDim
                            font.family: Theme.fontDisplay
                            font.pixelSize: 12
                            font.letterSpacing: 2
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sel.mode = chip.index;
                            sel.x1 = sel.y1 = sel.x2 = sel.y2 = 0;
                        }
                    }
                }
            }

            CutPanel {
                visible: sel.isRec
                anchors.verticalCenter: parent.verticalCenter
                width: audioText.implicitWidth + 28
                height: 44
                padding: 0
                cutTopRight: 0
                scanlines: false
                color: "transparent"
                borderColor: sel.audio ? Theme.magenta : Qt.alpha(Theme.magenta, 0.4)
                Text {
                    id: audioText
                    anchors.centerIn: parent
                    text: "A · AUDIO " + (sel.audio ? "ON" : "OFF")
                    color: sel.audio ? "#ff7ab0" : Theme.textDim
                    font.family: Theme.fontDisplay
                    font.pixelSize: 12
                    font.letterSpacing: 2
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sel.audio = !sel.audio
                }
            }
        }
    }

    // ── Ayuda ──
    CutPanel {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        padding: 12
        cutTopRight: 0
        color: Qt.alpha(Theme.bg, 0.95)
        borderColor: Qt.alpha(sel.tone, 0.22)

        Text {
            readonly property string label: sel.modes[sel.mode].label
            readonly property var hints: label === "VENTANA" ? [["MOVER", "elegir ventana"], ["CLIC / ↵", "capturar"], ["ESC", "cancelar"]] : label === "PANTALLA" ? [["CLIC / ↵", "capturar este monitor"], ["ESC", "cancelar"]] : [["ARRASTRA", "zona"], ["CLIC", "ajustar a ventana"], ["↵", sel.isRec ? "empezar a grabar" : "capturar"], ["ESPACIO", "pantalla completa"], ["ESC", "cancelar"]]
            textFormat: Text.StyledText
            text: hints.map(h => `<font color="${sel.tone}">${h[0]}</font> ${h[1]}`).join("    ")
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
            font.letterSpacing: 1.2
        }
    }

    Scanlines {
        anchors.fill: parent
        lineOpacity: 0.22
    }
}
