import QtQuick
import QtQuick.Shapes
import qs.common

// Panel con esquinas recortadas en chaflán.
// Uso:
//   CutPanel { cutTopRight: Theme.cut; Text { … } }
Item {
    id: root

    // Recorte de cada esquina en px (0 = esquina recta)
    property int cutTopLeft: 0
    property int cutTopRight: Theme.cut
    property int cutBottomRight: 0
    property int cutBottomLeft: 0

    property color color: Theme.surface
    property color borderColor: Theme.accentDim
    property real borderWidth: Theme.border
    property int padding: Theme.pad
    property bool scanlines: Theme.scanlines

    // Lo que pongas dentro de CutPanel { } va a 'inner'
    default property alias content: inner.data

    implicitWidth: inner.childrenRect.width + padding * 2
    implicitHeight: inner.childrenRect.height + padding * 2

    // El trazo se centra en la línea: lo metemos medio grosor hacia dentro
    // para que el borde no se corte en los bordes del Item.
    readonly property real _o: borderWidth / 2

    // Contorno en sentido horario desde arriba-izquierda (lo usan Shape y Scanlines)
    readonly property var points: {
        const w = width, h = height, o = _o;
        const tl = cutTopLeft, tr = cutTopRight;
        const br = cutBottomRight, bl = cutBottomLeft;
        return [Qt.point(o + tl, o), Qt.point(w - o - tr, o), Qt.point(w - o, o + tr), Qt.point(w - o, h - o - br), Qt.point(w - o - br, h - o), Qt.point(o + bl, h - o), Qt.point(o, h - o - bl), Qt.point(o, o + tl), Qt.point(o + tl, o),];
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer   // antialiasing en las diagonales

        ShapePath {
            fillColor: root.color
            strokeColor: root.borderColor
            strokeWidth: root.borderWidth
            joinStyle: ShapePath.MiterJoin

            PathPolyline {
                path: root.points
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }

    // Encima de todo, recortado a la forma del panel
    Scanlines {
        anchors.fill: parent
        clipPath: root.points
        visible: root.scanlines
    }
}
