pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Emojis: lista (assets/emoji.json, emojibase en español) + los más usados
Singleton {
    id: root

    property var all: []            // [{ e, n (nombre), g (grupo), k (palabras clave) }]
    property var usage: ({})        // { "😂": 12, … }

    readonly property var defaults: ["😂", "👍", "❤️", "🔥", "😭", "🤔", "🎉", "👀"]
    readonly property string usageFile: Quickshell.statePath("emoji-usage.json")

    // Pestañas: [grupo de emojibase, nombre]
    readonly property var groups: [[0, "CARAS"], [1, "GENTE"], [3, "NATURALEZA"], [4, "COMIDA"], [6, "ACTIVIDADES"], [5, "VIAJES"], [7, "OBJETOS"], [8, "SÍMBOLOS"], [9, "BANDERAS"]]

    // Los 8 de la rueda: los más usados, completados con los de serie
    readonly property var wheel: {
        const used = Object.keys(usage).sort((a, b) => usage[b] - usage[a]);
        const list = used.concat(defaults.filter(d => !used.includes(d)));
        return list.slice(0, 8);
    }

    function find(e) {
        return all.find(x => x.e === e) ?? {
            e: e,
            n: "",
            g: 0,
            k: ""
        };
    }

    function inGroup(g) {
        return all.filter(x => x.g === g);
    }

    function search(q) {
        q = q.toLowerCase().trim();
        if (q === "")
            return [];
        return all.filter(x => x.n.includes(q) || x.k.includes(q)).slice(0, 240);
    }

    // Copia el emoji y lo escribe en la ventana activa (o solo lo copia)
    function pick(e, andType) {
        const u = Object.assign({}, root.usage);
        u[e] = (u[e] ?? 0) + 1;
        root.usage = u;
        usageView.setText(JSON.stringify(u));
        pending.emoji = e;
        pending.andType = andType;
        pending.restart();        // espera a que se cierre el panel y vuelva el foco
    }
    Timer {
        id: pending
        property string emoji: ""
        property bool andType: true
        interval: 150
        // Se pega desde el portapapeles (escribirlo con wtype rompe los emojis en apps XWayland).
        // En terminales el atajo de pegar es Ctrl+Shift+V.
        onTriggered: Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy || exit; [ \"$2\" = 1 ] || exit 0; sleep 0.1; " + "case \"$(hyprctl activewindow -j | jq -r .class)\" in " + "foot|kitty|Alacritty|org.wezfurlong.wezterm|com.mitchellh.ghostty|org.kde.konsole) wtype -M ctrl -M shift v -m shift -m ctrl ;; " + "*) wtype -M ctrl v -m ctrl ;; esac", "sh", emoji, andType ? "1" : "0"])
    }

    FileView {
        path: Quickshell.shellDir + "/assets/emoji.json"
        blockLoading: true
        onLoaded: {
            try {
                root.all = JSON.parse(text());
            } catch (err) {
                console.warn("ancient emoji: no se pudo leer assets/emoji.json → " + err);
            }
        }
    }
    FileView {
        id: usageView
        path: root.usageFile
        blockLoading: true
        onLoaded: {
            try {
                root.usage = JSON.parse(text()) ?? {};
            } catch (err) {
                root.usage = {};
            }
        }
    }
}
