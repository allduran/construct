pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Versículo del día. Las citas van en el repo; el texto, en un archivo local tuyo (RVR1960).
Singleton {
    id: root

    readonly property string biblePath: Quickshell.env("HOME") + "/.local/share/construct/bible/rvr1960.json"
    readonly property string version: "RVR1960"

    readonly property var books: ["Génesis", "Éxodo", "Levítico", "Números", "Deuteronomio", "Josué", "Jueces", "Rut", "1 Samuel", "2 Samuel", "1 Reyes", "2 Reyes", "1 Crónicas", "2 Crónicas", "Esdras", "Nehemías", "Ester", "Job", "Salmos", "Proverbios", "Eclesiastés", "Cantares", "Isaías", "Jeremías", "Lamentaciones", "Ezequiel", "Daniel", "Oseas", "Joel", "Amós", "Abdías", "Jonás", "Miqueas", "Nahúm", "Habacuc", "Sofonías", "Hageo", "Zacarías", "Malaquías", "Mateo", "Marcos", "Lucas", "Juan", "Hechos", "Romanos", "1 Corintios", "2 Corintios", "Gálatas", "Efesios", "Filipenses", "Colosenses", "1 Tesalonicenses", "2 Tesalonicenses", "1 Timoteo", "2 Timoteo", "Tito", "Filemón", "Hebreos", "Santiago", "1 Pedro", "2 Pedro", "1 Juan", "2 Juan", "3 Juan", "Judas", "Apocalipsis"]

    // [libro (1–66), capítulo, versículo, versículo final opcional]
    readonly property var refs: [[1, 1, 1], [19, 23, 1], [43, 3, 16], [45, 8, 28], [50, 4, 13], [24, 29, 11], [20, 3, 5, 6], [23, 40, 31], [45, 12, 2], [49, 2, 8, 9], [58, 11, 1], [19, 46, 1], [40, 11, 28], [47, 5, 17], [48, 2, 20], [62, 4, 19], [19, 119, 105], [6, 1, 9], [40, 6, 33], [45, 5, 8], [43, 14, 6], [59, 1, 5], [60, 5, 7], [50, 4, 6, 7], [19, 37, 4], [20, 16, 3], [23, 41, 10], [45, 15, 13], [55, 1, 7], [58, 4, 12], [43, 1, 1], [19, 27, 1], [40, 5, 16], [51, 3, 23], [45, 10, 9], [20, 18, 10], [25, 3, 22, 23], [19, 91, 1, 2], [43, 16, 33], [47, 12, 9], [49, 6, 10], [58, 12, 1, 2], [54, 4, 12], [40, 28, 19, 20], [44, 1, 8], [19, 139, 14], [23, 53, 5], [45, 6, 23], [48, 5, 22, 23], [62, 1, 9], [43, 8, 32], [19, 34, 8], [20, 4, 23], [23, 26, 3], [46, 10, 13], [50, 1, 6], [59, 4, 8], [19, 51, 10], [45, 3, 23, 24], [49, 4, 32], [43, 15, 5], [40, 7, 7], [19, 103, 12], [52, 5, 16, 18], [23, 55, 8, 9], [24, 33, 3], [58, 13, 8], [19, 121, 1, 2], [46, 13, 4, 7], [43, 11, 25], [19, 16, 11], [20, 22, 6], [45, 1, 16], [66, 21, 4], [33, 6, 8], [35, 3, 17, 18], [36, 3, 17], [5, 31, 6], [27, 2, 20, 21], [19, 1, 1, 2], [47, 4, 16, 17], [51, 1, 16, 17], [62, 3, 1], [42, 1, 37], [49, 3, 20], [55, 3, 16, 17], [19, 62, 1, 2], [40, 22, 37, 39], [43, 10, 10], [45, 12, 12], [58, 10, 23], [19, 118, 24], [60, 1, 3], [22, 8, 7], [26, 36, 26], [39, 3, 6], [14, 7, 14], [18, 19, 25], [19, 90, 12], [66, 3, 20], [41, 10, 45], [44, 4, 12], [46, 15, 58]]

    property var bible: null
    property var bookKeys: ({})    // nombre normalizado → clave del libro en tu JSON

    // "Éxodo" → "exodo" · "1 Corintios" → "1corintios"
    function norm(s: string): string {
        return s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/\s+/g, "").toLowerCase();
    }

    // Capítulo como lista o como objeto { "1": "…" }: devuelve el versículo v (1 = primero)
    function verseAt(chapter, v: int): string {
        if (!chapter)
            return "";
        return Array.isArray(chapter) ? (chapter[v - 1] ?? "") : (chapter[String(v)] ?? "");
    }

    // Libro n (1–66) en cualquiera de los dos formatos
    function bookAt(n: int) {
        if (!bible)
            return null;
        if (Array.isArray(bible))
            return bible[n - 1]?.chapters ?? null;
        const target = norm(books[n - 1]);
        const key = bookKeys[target] ?? Object.keys(bookKeys).find(k => (k.startsWith(target) || target.startsWith(k) || k.endsWith(target)) && /^\d/.test(k) === /^\d/.test(target));      // "juan" nunca casa con "1juan"
        return key !== undefined ? bible[bookKeys[key] ?? key] : null;
    }
    readonly property bool available: bible !== null

    // Cambia a medianoche
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property int dayOfYear: {
        const d = clock.date;
        return Math.floor((d - new Date(d.getFullYear(), 0, 0)) / 86400000);
    }
    readonly property var ref: refs[(dayOfYear + clock.date.getFullYear()) % refs.length]

    readonly property string reference: `${books[ref[0] - 1]} ${ref[1]}:${ref[2]}${ref[3] ? "-" + ref[3] : ""}`

    readonly property string text: {
        const book = bookAt(ref[0]);
        if (!book)
            return "";
        const ch = Array.isArray(book) ? book[ref[1] - 1] : book[String(ref[1])];
        const out = [];
        for (let v = ref[2]; v <= (ref[3] ?? ref[2]); v++) {
            const t = verseAt(ch, v);
            if (t)
                out.push(String(t));
        }
        return out.join(" ").replace(/\{[^}]*\}|<[^>]*>|¶/g, "").replace(/\s+/g, " ").trim();
    }

    function copy(): void {
        if (text)
            Quickshell.execDetached(["wl-copy", `«${text}» — ${reference} (${version})`]);
    }

    FileView {
        path: root.biblePath
        watchChanges: true                  // si pones el archivo con construct abierto, lo coge solo
        onFileChanged: reload()
        onLoaded: {
            try {
                const b = JSON.parse(text());
                if (Array.isArray(b) && b.length === 66) {
                    root.bookKeys = {};
                    root.bible = b;
                } else if (b && typeof b === "object") {
                    const keys = {};
                    for (const k of Object.keys(b))
                        keys[root.norm(k)] = k;
                    root.bookKeys = keys;
                    root.bible = b;
                } else {
                    root.bible = null;
                }
            } catch (e) {
                console.warn("construct: no se pudo leer", root.biblePath, e);
                root.bible = null;
            }
        }
        onLoadFailed: root.bible = null
    }
}
