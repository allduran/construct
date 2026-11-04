pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Portapapeles: historial de cliphist + textos fijados (no caducan)
Singleton {
    id: root

    property var history: []        // entradas de cliphist
    property var pins: []           // textos fijados (se guardan en clip-pins.json)
    property string fullText: ""    // texto completo de la entrada elegida
    property int thumbStamp: 0      // cambia al terminar las miniaturas (refresca las imágenes)

    readonly property string thumbDir: Quickshell.env("XDG_RUNTIME_DIR") + "/construct-clip"
    readonly property string pinsFile: Quickshell.statePath("clip-pins.json")

    // Fijados primero, luego el historial
    readonly property var entries: pins.map((t, i) => ({
                id: "pin" + i,
                kind: root.classify(t),
                text: t.split("\n")[0],
                info: "fijado",
                pinned: true,
                full: t
            })).concat(history)

    function refresh() {
        if (!list.running)
            list.running = true;
    }

    function thumb(e) {
        return "file://" + root.thumbDir + "/" + e.id + ".png?" + root.thumbStamp;
    }

    // Carga el texto completo para la vista previa
    function load(e) {
        root.fullText = "";
        if (!e || e.kind === "IMAGEN")
            return;
        if (e.pinned) {
            root.fullText = e.full;
            return;
        }
        txt.command = ["cliphist", "decode", e.id];
        txt.running = true;
    }

    // Deja la entrada en el portapapeles y, si se pide, la pega con Ctrl+V
    function use(e, andPaste) {
        const src = e.pinned ? "printf '%s' \"$1\"" : "cliphist decode \"$1\"";
        const tail = andPaste ? " && sleep 0.2 && case \"$(hyprctl activewindow -j | jq -r .class)\" in " + "foot|kitty|Alacritty|org.wezfurlong.wezterm|com.mitchellh.ghostty|org.kde.konsole) wtype -M ctrl -M shift v -m shift -m ctrl ;; " + "*) wtype -M ctrl v -m ctrl ;; esac" : "";
        Quickshell.execDetached(["sh", "-c", src + " | wl-copy" + tail, "sh", e.pinned ? e.full : e.id]);
    }

    function remove(e) {
        if (e.pinned) {
            root.pins = root.pins.filter(t => t !== e.full);
            root.savePins();
            return;
        }
        del.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", e.line];
        del.running = true;
    }

    // Fija / quita (las imágenes no se fijan). Para fijar usa el texto ya cargado.
    function togglePin(e) {
        if (!e || e.kind === "IMAGEN")
            return;
        if (e.pinned)
            root.pins = root.pins.filter(t => t !== e.full);
        else if (root.fullText !== "" && !root.pins.includes(root.fullText))
            root.pins = [root.fullText].concat(root.pins);
        root.savePins();
    }

    function classify(p) {
        if (p.startsWith("[[ binary data"))
            return "IMAGEN";
        if (/^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(p.trim()))
            return "COLOR";
        if (/^https?:\/\//.test(p))
            return "ENLACE";
        if (/[{};]|=>|::|^\s*(import|const|let|var|def|function|class|property|#include)\b/.test(p))
            return "CÓDIGO";
        return "TEXTO";
    }

    // ── Fijados ──
    FileView {
        id: pinsView
        path: root.pinsFile
        blockLoading: true
        onLoaded: root.readPins()
    }
    function readPins() {
        try {
            const p = JSON.parse(pinsView.text());
            root.pins = Array.isArray(p) ? p : [];
        } catch (err) {
            root.pins = [];
        }
    }
    function savePins() {
        pinsView.setText(JSON.stringify(root.pins));
    }
    Component.onCompleted: readPins()

    // ── cliphist ──
    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const images = [];
                root.history = this.text.split("\n").filter(l => l.includes("\t")).map(l => {
                    const tab = l.indexOf("\t");
                    const id = l.slice(0, tab);
                    const preview = l.slice(tab + 1);
                    const kind = root.classify(preview);
                    let text = preview;
                    let info = kind.toLowerCase();
                    if (kind === "IMAGEN") {
                        // "[[ binary data 412 KiB png 1920x1080 ]]"
                        const m = preview.match(/data\s+([\d.]+\s*\w+)\s+(\w+)\s+(\d+)x(\d+)/);
                        text = m ? "Imagen · " + m[3] + " × " + m[4] : "Imagen";
                        info = m ? m[2].toUpperCase() + " · " + m[1] : "imagen";
                        images.push(id);
                    }
                    return {
                        id: id,
                        line: l,
                        kind: kind,
                        text: text,
                        info: info,
                        pinned: false
                    };
                });
                root.makeThumbs(images);
            }
        }
    }

    // Miniaturas de las imágenes (una vez por imagen, en XDG_RUNTIME_DIR)
    function makeThumbs(ids) {
        if (ids.length === 0)
            return;
        thumbs.command = ["sh", "-c", "d=\"$1\"; shift; mkdir -p \"$d\"; for id; do [ -s \"$d/$id.png\" ] || cliphist decode \"$id\" > \"$d/$id.png\"; done", "sh", root.thumbDir].concat(ids);
        thumbs.running = true;
    }

    Process {
        id: thumbs
        onExited: root.thumbStamp++
    }
    Process {
        id: txt
        stdout: StdioCollector {
            onStreamFinished: root.fullText = this.text
        }
    }
    Process {
        id: del
        onExited: root.refresh()
    }
}
