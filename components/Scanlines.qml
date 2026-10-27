import QtQuick
import qs.common

// Líneas horizontales tipo CRT. Va encima del contenido (anchors.fill).
// clipPath (opcional): lista de Qt.point; solo se pinta dentro de ese polígono.
Canvas {
    id: root

    property var clipPath: null
    property real lineOpacity: 0.28
    property int spacing: 3          // una línea cada 3 px

    visible: Theme.scanlines

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onClipPathChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        // Recorta al polígono para no pintar en las esquinas en chaflán
        if (clipPath && clipPath.length) {
            ctx.beginPath();
            ctx.moveTo(clipPath[0].x, clipPath[0].y);
            for (let i = 1; i < clipPath.length; i++)
                ctx.lineTo(clipPath[i].x, clipPath[i].y);
            ctx.closePath();
            ctx.clip();
        }

        ctx.fillStyle = `rgba(0, 0, 0, ${lineOpacity})`;
        for (let y = 0; y < height; y += spacing)
            ctx.fillRect(0, y, width, 1);
    }
}
