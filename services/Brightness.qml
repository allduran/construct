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

    function run(args) {
        proc.command = ["brightnessctl", "-m", "-c", "backlight"].concat(args);
        proc.running = true;
    }

    function up() {
        run(["set", "5%+"]);
    }
    function down() {
        run(["set", value > 0.06 ? "5%-" : "1%"]);
    }   // nunca a 0 (pantalla negra)

    Process {
        id: proc
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true                     // lectura inicial
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }
}
