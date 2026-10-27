pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Red WiFi activa según NetworkManager (nmcli).
Singleton {
    id: root

    property string ssid: ""
    property int signal: 0                       // 0–100
    readonly property bool connected: ssid !== ""

    // Consulta la red activa: líneas "yes:MiRed:72" / "no:Otra:40"
    Process {
        id: query
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => l.startsWith("yes:"));
                if (!line) {
                    root.ssid = "";
                    root.signal = 0;
                    return;
                }
                const parts = line.split(":");
                root.signal = Number(parts.pop());
                // El SSID puede llevar ':' escapados como '\:'
                root.ssid = parts.slice(1).join(":").replace(/\\/g, "");
            }
        }
    }

    // NetworkManager avisa de cada cambio (conectar, desconectar, cambiar de red)
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: _ => debounce.restart()
        }
    }

    // Un cambio suele traer varias líneas seguidas: consultamos una sola vez
    Timer {
        id: debounce
        interval: 500
        onTriggered: query.running = true
    }

    // La intensidad de la señal no llega por 'monitor': se refresca cada 20 s
    Timer {
        interval: 20000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }
}
