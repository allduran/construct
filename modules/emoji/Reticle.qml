import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// RETÍCULA //: los 8 emojis más usados alrededor del ratón.
PanelWindow {
    id: ret
    visible: ShellState.emojiWheelOpen

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-reticle"
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
    readonly property int outerR: 230      // borde exterior de los sectores
    readonly property int innerR: 78       // núcleo octogonal
    readonly property real gap: 3.2        // grados de hueco entre sectores

    property real cx: width / 2
    property real cy: height / 2
    property bool placed: false
    property int hovered: -1               // sector apuntado (−1 = centro)
    property real needle: -90              // ángulo de la aguja en grados

    readonly property var items: Emoji.wheel
    readonly property var current: hovered >= 0 ? Emoji.find(items[hovered]) : null

    onVisibleChanged: {
        if (!visible)
            return;
        placed = false;
        hovered = -1;
        needle = -90;
        cursor.running = true;
        Qt.callLater(() => keys.forceActiveFocus());
    }

    function close() {
        ShellState.emojiWheelOpen = false;
    }
    function choose(i: int) {
        if (i < 0 || i >= items.length)
            return;
        close();
        Emoji.pick(items[i], true);
    }
    function openFull() {
        ShellState.emojiWheelOpen = false;
        ShellState.emojiOpen = true;
    }

    // Punto a 'r' px del centro del disco y 'deg' grados
    function pt(r: real, deg: real): point {
        const a = deg * Math.PI / 180;
        return Qt.point(disc.c + r * Math.cos(a), disc.c + r * Math.sin(a));
    }

    // Posición del ratón → coordenadas de esta pantalla (sin salirse por los bordes)
    Process {
        id: cursor
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split(",").map(Number);
                const mon = Hyprland.focusedMonitor;
                const x = p[0] - (mon?.x ?? 0), y = p[1] - (mon?.y ?? 0);
                const m = ret.outerR + 56;
                ret.cx = Math.max(m, Math.min(ret.width - m, isNaN(x) ? ret.width / 2 : x));
                ret.cy = Math.max(m, Math.min(ret.height - m, isNaN(y) ? ret.height / 2 : y));
                ret.placed = true;
            }
        }
    }

    // Ratón: el ángulo elige el sector
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: m => {
            const dx = m.x - ret.cx, dy = m.y - ret.cy;
            const ang = Math.atan2(dy, dx) * 180 / Math.PI;
            ret.needle = ang;
            ret.hovered = Math.hypot(dx, dy) < ret.innerR ? -1 : ((Math.round((ang + 90) / 45) % 8) + 8) % 8;
        }
        onClicked: ret.hovered >= 0 ? ret.choose(ret.hovered) : ret.openFull()
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape)
                ret.close();
            else if (e.key === Qt.Key_Tab)
                ret.openFull();
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_8)
                ret.choose(e.key - Qt.Key_1);
            else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && ret.hovered >= 0)
                ret.choose(ret.hovered);
            else
                return;
            e.accepted = true;
        }
    }

    // Viñeta: oscurece todo menos alrededor de la retícula
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: ret.cx
                centerY: ret.cy
                focalX: ret.cx
                focalY: ret.cy
                centerRadius: 420
                GradientStop {
                    position: 0.0
                    color: Qt.alpha(Theme.bg, 0.55)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.alpha(Theme.bg, 0.88)
                }
            }
            PathRectangle {
                width: ret.width
                height: ret.height
            }
        }
    }

    // ── La retícula ──
    Item {
        id: disc
        readonly property real c: width / 2
        width: (ret.outerR + 56) * 2
        height: width
        x: ret.cx - c
        y: ret.cy - c
        opacity: ret.placed ? 1 : 0
        scale: ret.placed ? 1 : 0.88
        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        // Marcas de radar (cada 5°, largas cada 45°), girando despacio
        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                for (let d = 0; d < 360; d += 5) {
                    const big = d % 45 === 0;
                    const a = d * Math.PI / 180;
                    const r1 = ret.outerR + 30, r2 = ret.outerR + (big ? 50 : 40);
                    ctx.strokeStyle = big ? Theme.accent : Theme.accentDim;
                    ctx.lineWidth = big ? 2 : 1;
                    ctx.beginPath();
                    ctx.moveTo(disc.c + r1 * Math.cos(a), disc.c + r1 * Math.sin(a));
                    ctx.lineTo(disc.c + r2 * Math.cos(a), disc.c + r2 * Math.sin(a));
                    ctx.stroke();
                }
            }
            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 24000
                loops: Animation.Infinite
                running: ret.visible
            }
        }

        // Sectores
        Repeater {
            model: 8

            delegate: Item {
                id: sec
                required property int index
                anchors.fill: parent

                readonly property bool on: index === ret.hovered
                readonly property real mid: -90 + 45 * index
                readonly property real ro: on ? ret.outerR + 14 : ret.outerR
                readonly property string emoji: ret.items[index] ?? ""

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: sec.on ? Qt.alpha(Theme.accent, 0.2) : Qt.alpha(Theme.bg, 0.82)
                        strokeColor: sec.on ? Theme.accent : Theme.accentDim
                        strokeWidth: sec.on ? 2 : 1
                        joinStyle: ShapePath.MiterJoin
                        PathPolyline {
                            path: {
                                const a0 = sec.mid - 22.5 + ret.gap, a1 = sec.mid + 22.5 - ret.gap;
                                const ri = ret.innerR + 8;
                                return [ret.pt(ri, a0), ret.pt(sec.ro, a0), ret.pt(sec.ro, a1), ret.pt(ri, a1), ret.pt(ri, a0)];
                            }
                        }
                    }
                }

                // Número del sector (tecla directa)
                Text {
                    readonly property point p: ret.pt(sec.ro - 18, sec.mid)
                    x: p.x - width / 2
                    y: p.y - height / 2
                    text: "0" + (sec.index + 1)
                    color: sec.on ? Theme.accent : Qt.alpha(Theme.textDim, 0.6)
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    readonly property point p: ret.pt((ret.outerR + ret.innerR) / 2 + (sec.on ? 8 : 0), sec.mid)
                    x: p.x - width / 2
                    y: p.y - height / 2
                    text: sec.emoji
                    font.family: ret.emojiFont
                    font.pixelSize: sec.on ? 44 : 34
                    Behavior on font.pixelSize {
                        NumberAnimation {
                            duration: 90
                        }
                    }
                }
            }
        }

        // Aguja: del núcleo al sector apuntado
        Shape {
            anchors.fill: parent
            visible: ret.hovered >= 0
            ShapePath {
                strokeColor: Theme.accent
                strokeWidth: 2
                fillColor: "transparent"
                startX: disc.c
                startY: disc.c
                PathLine {
                    x: ret.pt(ret.innerR - 6, ret.needle).x
                    y: ret.pt(ret.innerR - 6, ret.needle).y
                }
            }
        }

        // Núcleo octogonal
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: Theme.bg
                strokeColor: Theme.accent
                strokeWidth: 1.5
                joinStyle: ShapePath.MiterJoin
                PathPolyline {
                    path: Array.from({
                        length: 9
                    }, (_, i) => ret.pt(ret.innerR - 6, -90 + 22.5 + 45 * i))
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ret.current?.e ?? "✛"
                color: Theme.accent
                font.family: ret.current ? ret.emojiFont : Theme.fontMono
                font.pixelSize: ret.current ? 46 : 30
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ret.hovered >= 0 ? String(45 * ret.hovered).padStart(3, "0") + "°" : "TODOS"
                color: Theme.accent
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 1.6
            }
        }
    }

    // ── OBJETIVO FIJADO: a la derecha (o a la izquierda si no cabe) ──
    Column {
        readonly property bool leftSide: ret.cx + disc.c + 330 > ret.width
        visible: ret.placed && ret.current !== null
        width: 300
        x: leftSide ? ret.cx - disc.c - width - 10 : ret.cx + disc.c + 10
        y: ret.cy - 80
        spacing: 10

        readonly property int uses: Emoji.usage[ret.current?.e] ?? 0
        readonly property int maxUses: Math.max(1, ...ret.items.map(e => Emoji.usage[e] ?? 0))

        Text {
            text: "OBJETIVO FIJADO"
            color: Theme.accent
            font.family: Theme.fontDisplay
            font.pixelSize: 12
            font.letterSpacing: Theme.tracking
        }
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.accentDim
        }
        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: ret.current?.n ?? ""
            color: Theme.textBright
            font.family: Theme.fontMono
            font.pixelSize: 20
        }
        Text {
            text: `${parent.uses} usos · sector 0${ret.hovered + 1}`
            color: Theme.textDim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsSm
        }
        Row {
            spacing: 3
            Repeater {
                model: 12
                Rectangle {
                    required property int index
                    width: (300 - 11 * 3) / 12
                    height: 8
                    color: index < Math.round(parent.parent.uses / parent.parent.maxUses * 12) ? Theme.accent : Theme.track
                }
            }
        }
    }

    // ── Ayuda ──
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        visible: ret.placed
        textFormat: Text.StyledText
        text: [["MOVER", "apuntar"], ["CLIC", "escribir"], ["1–8", "directo"], ["CENTRO / TAB", "GLIFOS completo"], ["ESC", "cancelar"]].map(h => `<font color="${Theme.accent}">${h[0]}</font> ${h[1]}`).join("   ")
        color: Theme.textDim
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsSm
        font.letterSpacing: 1.4
    }
}
