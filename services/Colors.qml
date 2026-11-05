pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Cuentagotas (hyprpicker) + paleta de los últimos colores.
Singleton {
    id: root

    property alias palette: store.palette      // ["#39ff88", …], el más nuevo primero
    property string last: ""
    signal picked(string hex)

    readonly property string gplPath: Quickshell.env("HOME") + "/Pictures/Paletas/construct.gpl"

    function pick(): void {
        if (!proc.running)
            proc.running = true;
    }
    function copy(text: string): void {
        Quickshell.execDetached(["wl-copy", text]);
    }

    function remove(hex: string): void {
        store.palette = store.palette.filter(c => c !== hex);
    }

    // "#39ff88" → los formatos que se pueden copiar
    function formats(hex: string): var {
        const c = Qt.color(hex);
        const r = Math.round(c.r * 255), g = Math.round(c.g * 255), b = Math.round(c.b * 255);
        const h = Math.round(Math.max(0, c.hslHue) * 360);
        const s = Math.round(c.hslSaturation * 100), l = Math.round(c.hslLightness * 100);
        return [
            {
                k: "HEX",
                v: hex.toUpperCase()
            },
            {
                k: "RGB",
                v: `rgb(${r}, ${g}, ${b})`
            },
            {
                k: "HSL",
                v: `hsl(${h}, ${s}%, ${l}%)`
            },
            {
                k: "QML",
                v: `Qt.rgba(${c.r.toFixed(2)}, ${c.g.toFixed(2)}, ${c.b.toFixed(2)}, 1)`
            }
        ];
    }

    // Luminancia relativa: decide si el texto encima va claro u oscuro
    function isLight(hex: string): bool {
        const c = Qt.color(hex);
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b > 0.55;
    }

    // Paleta de GIMP (la leen Krita, GIMP, Inkscape y Blender)
    function exportGpl(): void {
        const lines = ["GIMP Palette", "Name: construct", "Columns: 8", "#"];
        for (const hex of store.palette) {
            const c = Qt.color(hex);
            const rgb = [c.r, c.g, c.b].map(x => String(Math.round(x * 255)).padStart(3, " ")).join(" ");
            lines.push(`${rgb}\t${hex}`);
        }
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1" && notify-send -a Construct "Paleta exportada" "$1"', "sh", gplPath, lines.join("\n")]);
    }

    // -f hex: imprime el color · -z: lupa
    Process {
        id: proc
        command: ["hyprpicker", "-n", "-f", "hex", "-z"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Busca el #rrggbb aunque venga con códigos de color o texto alrededor
                const m = text.match(/#[0-9a-fA-F]{6}/);
                if (!m)
                    // Esc en hyprpicker: nada
                    return;
                const hex = m[0].toLowerCase();
                root.last = hex;
                store.palette = [hex].concat(store.palette.filter(c => c !== hex)).slice(0, 24);
                root.copy(hex);
                root.picked(hex);
            }
        }
    }

    FileView {
        path: Quickshell.statePath("palette.json")
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: store
            property var palette: []
        }
    }
}
