import QtQuick
import QtQuick.Effects
import qs.common

// Pastilla de Matrix: botón cápsula azul o roja.
// Uso: Pill { red: true; title: "PASTILLA ROJA"; sub: "apagar"; onClicked: … }
Rectangle {
    id: pill

    property bool red: false
    property string title: ""
    property string sub: ""
    signal clicked

    readonly property color tone: red ? "#ff3b3b" : "#3d7bff"

    width: 340
    height: 88
    radius: height / 2
    color: Qt.alpha(red ? "#6e0c12" : "#14286e", hover.hovered ? 0.8 : 0.55)
    border.color: tone
    border.width: 1

    scale: hover.hovered ? 1.03 : 1
    Behavior on scale {
        NumberAnimation {
            duration: 120
        }
    }

    // Halo del color de la pastilla
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: pill.tone
        shadowBlur: 0.8
        shadowOpacity: hover.hovered ? 0.7 : 0.4
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        x: 26
        spacing: 18

        // La pastilla dibujada: cápsula con brillo a la izquierda
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 54
            height: 26
            radius: 13
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Qt.lighter(pill.tone, 1.6)
                }
                GradientStop {
                    position: 0.45
                    color: pill.tone
                }
                GradientStop {
                    position: 1.0
                    color: Qt.darker(pill.tone, 2.2)
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: pill.title
                color: pill.red ? "#ffecec" : "#eaf0ff"
                font.family: Theme.fontDisplay
                font.pixelSize: 16
                font.letterSpacing: Theme.tracking
            }
            Text {
                text: pill.sub
                color: pill.red ? "#f0c0c0" : "#b8c8f0"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSm
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: pill.clicked()
    }
}
