import QtQuick
import qs.common

// Lluvia de katakana estilo Matrix.
// Solo anima mientras running && visible: cerrada, no consume nada.
Canvas {
    id: root

    property bool running: Theme.rain
    property int fontSize: 18
    property int fps: 24
    property color color: Theme.accent          // estela
    property color headColor: Theme.textBright  // carácter que cae
    property color background: Theme.bg
    property real fade: 0.08      // cuánto se borra por fotograma: más alto = estela más corta
    property real density: 0.975  // más alto = las columnas tardan más en reiniciar

    readonly property string glyphs: "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾗﾘﾜ0123456789:.=*+<>¦"

    // Fila actual de cada columna (negativa = aún no ha entrado en pantalla)
    property var drops: []

    function randomGlyph(): string {
        return glyphs[Math.floor(Math.random() * glyphs.length)];
    }

    onWidthChanged: drops = []    // fuerza a recalcular columnas en el próximo fotograma
    onHeightChanged: drops = []

    onPaint: {
        const ctx = getContext("2d");
        const fs = fontSize;
        const cols = Math.ceil(width / fs);

        // Primer fotograma (o cambio de tamaño): fondo sólido y columnas escalonadas
        if (drops.length !== cols) {
            drops = Array.from({
                length: cols
            }, () => -Math.floor(Math.random() * height / fs));
            ctx.globalAlpha = 1;
            ctx.fillStyle = background;
            ctx.fillRect(0, 0, width, height);
        }

        // Velo semitransparente: lo dibujado antes se va oscureciendo → estela
        ctx.globalAlpha = fade;
        ctx.fillStyle = background;
        ctx.fillRect(0, 0, width, height);
        ctx.globalAlpha = 1;

        ctx.font = `${fs}px "${Theme.fontKana}"`;
        ctx.textBaseline = "top";

        for (let i = 0; i < cols; i++) {
            const x = i * fs;
            const y = drops[i] * fs;

            if (y >= 0) {
                // La cabeza anterior pasa a ser estela verde (con otro carácter: parpadeo)
                ctx.fillStyle = background;
                ctx.fillRect(x, y - fs, fs, fs);
                ctx.fillStyle = color;
                ctx.fillText(randomGlyph(), x, y - fs);

                // Nueva cabeza brillante
                ctx.fillStyle = headColor;
                ctx.fillText(randomGlyph(), x, y);
            }

            drops[i]++;
            // Al salir por abajo, reinicia arriba con algo de azar
            if (y > height && Math.random() > density)
                drops[i] = 0;
        }
    }

    Timer {
        interval: 1000 / root.fps
        running: root.running && root.visible
        repeat: true
        onTriggered: root.requestPaint()
    }
}
