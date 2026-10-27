pragma Singleton
import Quickshell
import QtQuick

// Tema de construct: todo lo visual sale de aquí.
// Uso: import qs.common  →  Theme.accent, Theme.fontMono…
Singleton {
    id: root

    // ── Paleta ─────────────────────────────────────────
    readonly property color bg: "#020403"   // fondo base
    readonly property color surface: Qt.rgba(3 / 255, 10 / 255, 6 / 255, 0.88)  // paneles
    readonly property color accent: "#39ff88"   // fósforo
    readonly property color cyan: "#19e6f0"
    readonly property color magenta: "#ff2e88"   // urgente / alertas
    readonly property color yellow: "#f5e50a"   // avisos
    readonly property color accentFg: "#020403"   // texto sobre acento

    readonly property color text: "#d8ffe8"   // texto principal
    readonly property color textBright: "#eafff2"   // títulos, valores
    readonly property color textDim: "#6fa083"   // etiquetas (pasa 4.5:1 sobre bg)

    // Variantes del acento con alfa: bordes y pistas de barras
    readonly property color accentDim: Qt.alpha(accent, 0.38)
    readonly property color accentFaint: Qt.alpha(accent, 0.14)
    readonly property color track: Qt.alpha(textDim, 0.22)

    // ── Fuentes ────────────────────────────────────────
    FontLoader {
        id: chakraMed
        source: Qt.resolvedUrl("../fonts/ChakraPetch-Medium.ttf")
    }
    FontLoader {
        id: chakraBold
        source: Qt.resolvedUrl("../fonts/ChakraPetch-Bold.ttf")
    }
    FontLoader {
        id: jetbrains
        source: Qt.resolvedUrl("../fonts/JetBrainsMono.ttf")
    }
    FontLoader {
        id: mplus
        source: Qt.resolvedUrl("../fonts/MPLUS1Code.ttf")
    }

    readonly property string fontDisplay: chakraBold.name   // títulos, reloj
    readonly property string fontMono: jetbrains.name    // texto general
    readonly property string fontKana: mplus.name        // lluvia de katakana

    // Tamaños (px)
    readonly property int fsXs: 11
    readonly property int fsSm: 12
    readonly property int fsMd: 14
    readonly property int fsLg: 18
    readonly property int fsXl: 24

    // Espaciado de etiquetas tipo HUD
    readonly property real tracking: 2.4   // font.letterSpacing en títulos

    // ── Geometría ──────────────────────────────────────
    readonly property int cut: 14   // tamaño del recorte de esquina en paneles
    readonly property int cutSmall: 8    // botones, chips
    readonly property int gap: 10   // separación entre módulos
    readonly property int pad: 14   // padding interior de paneles
    readonly property int barHeight: 46
    readonly property int border: 1

    // ── Efectos (se podrán cambiar desde el panel de control) ──
    property bool rain: true    // lluvia de katakana de fondo
    property bool scanlines: true    // líneas CRT sobre los paneles
    property bool glitch: true    // glitch ocasional en títulos
}
