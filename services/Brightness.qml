pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Brillo de la pantalla del portátil (brightnessctl)
Singleton {
    id: root

    property real value: 0           // 0–1
    property bool available: false   // false en equipos sin backlight (sobremesa)

    // Salida de "brightnessctl -m": dispositivo,clase,actual,porcentaje%,máximo
    function parse(text) {
        const f = text.trim().split("\n")[0].split(",");
        if (f.length >= 5) {
            root.value = Number(f[2]) / Number(f[4]);
            root.available = true;
        }
    }

    // Cambia con un proceso aparte (nunca choca con la lectura) y luego relee
    function run(args) {
        Quickshell.execDetached(["brightnessctl", "-c", "backlight"].concat(args));
        refresh.restart();
    }

    function up() {
        run(["set", "5%+"]);
    }
    function down() {
        run(["set", value > 0.06 ? "5%-" : "1%"]);   // nunca a 0 (pantalla negra)
    }

    // Slider: valor exacto 0–1 (mínimo 1 %). Se actualiza 'value' al momento
    // para que el slider no "salte atrás" mientras se arrastra.
    function set(v) {
        root.value = v;
        run(["set", Math.max(1, Math.round(v * 100)) + "%"]);
    }

    // Relee el valor un instante después del cambio
    Timer {
        id: refresh
        interval: 80
        onTriggered: {
            proc.running = false;
            proc.running = true;
        }
    }

    Process {
        id: proc
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true                     // lectura inicial
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }
}
