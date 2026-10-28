pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Búsqueda de archivos y carpetas en el home con fd.
// Asíncrona: search(q) lanza la búsqueda y 'results' se rellena al terminar.
Singleton {
    id: root

    property var results: []        // ya normalizados { name, sub, icon, abbr, hint, run }
    property bool searching: false
    property string _q: ""

    readonly property string home: Quickshell.env("HOME")

    function search(query: string): void {
        // ":~/proyecto" → "proyecto"
        _q = query.trim().replace(/^:/, "").replace(/^~\/?/, "").trim();
        if (_q.length < 2) {         // con 1 letra saldría medio disco
            proc.running = false;
            results = [];
            searching = false;
            return;
        }
        debounce.restart();
    }

    function open(path: string): void {
        Quickshell.execDetached(["xdg-open", path]);
    }

    function toItem(path: string): var {
        const isDir = path.endsWith("/");
        const clean = path.replace(/\/+$/, "");
        const name = clean.split("/").pop();
        const ext = isDir ? "DIR" : name.includes(".") ? name.split(".").pop().slice(0, 3).toUpperCase() : "···";
        return {
            name: name,
            sub: clean.replace(home, "~"),
            icon: "",
            abbr: ext,
            hint: isDir ? "CARPETA" : "ARCHIVO",
            run: () => open(clean)
        };
    }

    // Espera a que dejes de escribir 200 ms antes de buscar
    Timer {
        id: debounce
        interval: 200
        onTriggered: {
            proc.running = false;     // corta la búsqueda anterior si seguía
            root.searching = true;
            proc.running = true;
        }
    }

    // Archivos y carpetas por separado: a las carpetas se les añade "/" para distinguirlas.
    // El texto va como argumento ($1), nunca pegado dentro del comando.
    Process {
        id: proc
        command: ["sh", "-c", 'fd -F -i --type f --max-results 40 -- "$1" "$HOME"; ' + 'fd -F -i --type d --max-results 20 -- "$1" "$HOME" | sed "s|/*$|/|"', "sh", root._q]

        stdout: StdioCollector {
            onStreamFinished: {
                const q = root._q.toLowerCase();
                root.results = text.split("\n").filter(p => p !== "").map(p => ({
                            p,
                            n: p.replace(/\/+$/, "").split("/").pop().toLowerCase()
                        }))
                // Primero los que empiezan por lo buscado, luego los de ruta más corta
                .sort((a, b) => (b.n.startsWith(q) - a.n.startsWith(q)) || a.p.length - b.p.length).slice(0, 30).map(x => root.toItem(x.p));
                root.searching = false;
            }
        }
    }
}
