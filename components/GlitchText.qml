import QtQuick
import qs.common

// Texto con glitch RGB ocasional (aberración cromática + temblor).
// Uso: GlitchText { text: "CNSTRCT//"; font.pixelSize: 18 }
Item {
    id: root

    property alias text: main.text
    property alias font: main.font
    property color color: Theme.accent

    property real strength: 3          // px de separación máxima
    property int minInterval: 2000     // ms entre glitches (aleatorio entre min y max)
    property int maxInterval: 5000

    // Estado de la animación
    property real shift: 0             // separación de canales magenta/cian
    property real jitter: 0            // desplazamiento horizontal del conjunto

    implicitWidth: main.implicitWidth
    implicitHeight: main.implicitHeight

    Text {
        text: main.text
        font: main.font
        color: Theme.magenta
        x: root.jitter - root.shift
        opacity: root.shift !== 0 ? 0.85 : 0
    }
    Text {
        text: main.text
        font: main.font
        color: Theme.cyan
        x: root.jitter + root.shift
        opacity: root.shift !== 0 ? 0.85 : 0
    }
    Text {
        id: main
        color: root.color
        x: root.jitter
    }

    // Ráfaga: 3 "fotogramas" rotos y vuelta a la normalidad
    SequentialAnimation {
        id: burst
        PropertyAction {
            target: root
            property: "shift"
            value: root.strength
        }
        PropertyAction {
            target: root
            property: "jitter"
            value: -root.strength
        }
        PauseAnimation {
            duration: 60
        }
        PropertyAction {
            target: root
            property: "shift"
            value: -root.strength * 0.7
        }
        PropertyAction {
            target: root
            property: "jitter"
            value: root.strength * 0.6
        }
        PauseAnimation {
            duration: 50
        }
        PropertyAction {
            target: root
            property: "shift"
            value: root.strength * 0.4
        }
        PropertyAction {
            target: root
            property: "jitter"
            value: 0
        }
        PauseAnimation {
            duration: 40
        }
        PropertyAction {
            target: root
            property: "shift"
            value: 0
        }
    }

    // Intervalo aleatorio para que no parezca un metrónomo
    Timer {
        interval: root.minInterval
        running: Theme.glitch && root.visible
        repeat: true
        onTriggered: {
            interval = root.minInterval + Math.random() * (root.maxInterval - root.minInterval);
            burst.restart();
        }
    }
}
