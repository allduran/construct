import QtQuick
import qs.common

// Lluvia de katakana estilo Matrix.
// Solo anima mientras running && visible: cerrada, no consume nada.
// Se pinta a 1/'downscale' de resolución y se escala sin suavizado (píxel duro):
// con 2, cuatro veces menos píxeles por fotograma.
Item {
    id: root

    property bool running: Theme.rain
    property int fontSize: 18                   // tamaño en pantalla
    property int fps: 15
    property int downscale: 2
    property color color: Theme.accent          // estela
    property color headColor: Theme.textBright  // carácter que cae
    property color background: Theme.bg
    property real fade: 0.08      // cuánto se borra por fotograma: más alto = estela más corta
    property real density: 0.975  // más alto = las columnas tardan más en reiniciar

    readonly property string glyphs: "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾗﾘﾜ0123456789:.=*+<>¦"

    function randomGlyph(): string {
        return glyphs[Math.floor(Math.random() * glyphs.length)];
    }

    Canvas {
        id: canvas
        width: Math.ceil(root.width / root.downscale)
        height: Math.ceil(root.height / root.downscale)
        scale: root.downscale
        transformOrigin: Item.TopLeft
        smooth: false

        // Fila actual de cada columna (negativa = aún no ha entrado en pantalla)
        property var drops: []

        onWidthChanged: drops = []    // fuerza a recalcular columnas en el próximo fotograma
        onHeightChanged: drops = []

        onPaint: {
            const ctx = getContext("2d");
            const fs = Math.max(4, Math.round(root.fontSize / root.downscale));
            const cols = Math.ceil(width / fs);
            const bg = root.background;

            // Primer fotograma (o cambio de tamaño): fondo sólido y columnas escalonadas
            if (drops.length !== cols) {
                drops = Array.from({
                    length: cols
                }, () => -Math.floor(Math.random() * height / fs));
                ctx.globalAlpha = 1;
                ctx.fillStyle = bg;
                ctx.fillRect(0, 0, width, height);
            }

            // Velo semitransparente: lo dibujado antes se va oscureciendo → estela
            ctx.globalAlpha = root.fade;
            ctx.fillStyle = bg;
            ctx.fillRect(0, 0, width, height);
            ctx.globalAlpha = 1;

            ctx.font = `${fs}px "${Theme.fontKana}"`;
            ctx.textBaseline = "top";

            for (let i = 0; i < cols; i++) {
                const x = i * fs;
                const y = drops[i] * fs;

                if (y >= 0) {
                    // La cabeza anterior pasa a ser estela (con otro carácter: parpadeo)
                    ctx.fillStyle = bg;
                    ctx.fillRect(x, y - fs, fs, fs);
                    ctx.fillStyle = root.color;
                    ctx.fillText(root.randomGlyph(), x, y - fs);

                    // Nueva cabeza brillante
                    ctx.fillStyle = root.headColor;
                    ctx.fillText(root.randomGlyph(), x, y);
                }

                drops[i]++;
                // Al salir por abajo, reinicia arriba con algo de azar
                if (y > height && Math.random() > root.density)
                    drops[i] = 0;
            }
        }
    }

    Timer {
        interval: 1000 / root.fps
        running: root.running && root.visible && !Theme.gameMode
        repeat: true
        onTriggered: canvas.requestPaint()
    }
}
