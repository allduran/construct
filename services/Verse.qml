pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Versículo del día. Las citas y su texto (RVR1960) van en data/verses.json,
// generado con scripts/gen-verses.py a partir de tu Biblia local.
Singleton {
    id: root

    readonly property string versesPath: Quickshell.shellDir + "/data/verses.json"
    readonly property string version: "RVR1960"

    readonly property var books: ["Génesis", "Éxodo", "Levítico", "Números", "Deuteronomio", "Josué", "Jueces", "Rut", "1 Samuel", "2 Samuel", "1 Reyes", "2 Reyes", "1 Crónicas", "2 Crónicas", "Esdras", "Nehemías", "Ester", "Job", "Salmos", "Proverbios", "Eclesiastés", "Cantares", "Isaías", "Jeremías", "Lamentaciones", "Ezequiel", "Daniel", "Oseas", "Joel", "Amós", "Abdías", "Jonás", "Miqueas", "Nahúm", "Habacuc", "Sofonías", "Hageo", "Zacarías", "Malaquías", "Mateo", "Marcos", "Lucas", "Juan", "Hechos", "Romanos", "1 Corintios", "2 Corintios", "Gálatas", "Efesios", "Filipenses", "Colosenses", "1 Tesalonicenses", "2 Tesalonicenses", "1 Timoteo", "2 Timoteo", "Tito", "Filemón", "Hebreos", "Santiago", "1 Pedro", "2 Pedro", "1 Juan", "2 Juan", "3 Juan", "Judas", "Apocalipsis"]

    // [{ ref: [libro, capítulo, versículo, final?], text }]
    property var entries: []
    readonly property bool available: entries.length > 0

    // Cambia a medianoche
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property int dayOfYear: {
        const d = clock.date;
        return Math.floor((d - new Date(d.getFullYear(), 0, 0)) / 86400000);
    }
    readonly property var entry: available ? entries[(dayOfYear + clock.date.getFullYear()) % entries.length] : null
    readonly property var ref: entry?.ref ?? [1, 1, 1]

    readonly property string reference: `${books[ref[0] - 1]} ${ref[1]}:${ref[2]}${ref[3] ? "-" + ref[3] : ""}`
    readonly property string text: entry?.text ?? ""

    function copy(): void {
        if (text)
            Quickshell.execDetached(["wl-copy", `«${text}» — ${reference} (${version})`]);
    }

    FileView {
        path: root.versesPath
        watchChanges: true                  // al regenerarlo con construct abierto, lo coge solo
        onFileChanged: reload()
        onLoaded: {
            try {
                const e = JSON.parse(text());
                root.entries = Array.isArray(e) ? e.filter(x => x && x.text) : [];
            } catch (err) {
                console.warn("construct: no se pudo leer", root.versesPath, err);
                root.entries = [];
            }
        }
        onLoadFailed: root.entries = []
    }
}
