pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Fondos de ~/Pictures/Wallpapers (cualquier nombre) + fondo, filtro e intensidad guardados.
// Filtros: 0 ORIGINAL · 1 TINTE · 2 FÓSFORO · 3 TERMINAL
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property var filterNames: ["ORIGINAL", "TINTE", "FÓSFORO", "TERMINAL"]

    property var list: []                       // [{ name, path, size }] por nombre
    property alias current: store.current       // ruta del fondo puesto
    property alias filter: store.filter
    property alias intensity: store.intensity   // 0–1

    function refresh() {
        if (!scan.running)
            scan.running = true;
    }

    function apply(path: string, f: int, k: real) {
        store.current = path;
        store.filter = f;
        store.intensity = Math.max(0, Math.min(1, k));
    }

    function sizeText(bytes: real): string {
        return bytes >= 1048576 ? (bytes / 1048576).toFixed(1).replace(".", ",") + " MB" : Math.round(bytes / 1024) + " KB";
    }

    // Tamaño y ruta de cada imagen (sin subcarpetas)
    Process {
        id: scan
        command: ["sh", "-c", 'find "$1" -maxdepth 1 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) -printf "%s\\t%p\\n" 2>/dev/null', "sh", root.dir]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = text.split("\n").filter(l => l.includes("\t")).map(l => {
                    const [size, path] = l.split("\t");
                    return {
                        name: path.split("/").pop(),
                        path,
                        size: Number(size)
                    };
                }).sort((a, b) => a.name.localeCompare(b.name));

                // Sin fondo guardado (o ya no existe): el primero de la carpeta
                if (root.list.length && !root.list.some(w => w.path === store.current))
                    store.current = root.list[0].path;
            }
        }
    }

    FileView {
        path: Quickshell.statePath("wallpaper.json")
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store
            property string current: ""
            property int filter: 2          // FÓSFORO por defecto
            property real intensity: 0.85
        }
    }
}
