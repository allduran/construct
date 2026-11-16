import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.common

// Imagen con los filtros de construct.
// filter: 0 ORIGINAL · 1 TINTE · 2 FÓSFORO · 3 TERMINAL · intensity: 0–1
Item {
    id: root
    property url source
    property int filter: 2
    property real intensity: 0.85
    property color tint: Theme.accent
    readonly property alias status: img.status

    readonly property real k: filter === 0 ? 0 : intensity

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // No cargar hasta conocer el tamaño (sourceSize 0 = decodificar a resolución completa).
        // Con ancho y alto + PreserveAspectCrop, Qt escala para cubrir: 1920x1080 → ~8 MB.
        source: root.width > 0 && root.height > 0 ? root.source : ""
        sourceSize: Qt.size(Math.ceil(root.width), Math.ceil(root.height))
        visible: root.filter === 0
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.filter !== 0
        // TINTE: algo de color original + velo · FÓSFORO/TERMINAL: gris → acento
        saturation: root.filter === 1 ? -0.5 * root.k : -root.k
        contrast: root.filter >= 2 ? 0.25 * root.k : 0
        brightness: root.filter >= 2 ? 0.05 * root.k : 0
        colorization: root.filter === 1 ? 0.55 * root.k : root.k
        colorizationColor: root.tint
    }

    // TERMINAL: scanlines + viñeta CRT
    Item {
        anchors.fill: parent
        visible: root.filter === 3
        opacity: root.k

        Scanlines {
            anchors.fill: parent
            lineOpacity: 0.35
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: root.width / 2
                    centerY: root.height / 2
                    focalX: centerX
                    focalY: centerY
                    centerRadius: Math.max(root.width, root.height) * 0.7
                    GradientStop {
                        position: 0.55
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(0, 0, 0, 0.75)
                    }
                }
                PathRectangle {
                    width: root.width
                    height: root.height
                }
            }
        }
    }
}
