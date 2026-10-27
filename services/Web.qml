pragma Singleton
import Quickshell
import QtQuick

// Búsqueda web del launcher. Prefijos tipo "!yt lofi".
// results() devuelve elementos ya normalizados { name, sub, icon, abbr, hint, run }.
Singleton {
    id: root

    // El primero es el motor por defecto
    readonly property var engines: [
        {
            bang: "g",
            name: "Google",
            url: "https://www.google.com/search?q=%s"
        },
        {
            bang: "d",
            name: "DuckDuckGo",
            url: "https://duckduckgo.com/?q=%s"
        },
        {
            bang: "yt",
            name: "YouTube",
            url: "https://www.youtube.com/results?search_query=%s"
        },
        {
            bang: "gh",
            name: "GitHub",
            url: "https://github.com/search?q=%s"
        },
        {
            bang: "aur",
            name: "AUR",
            url: "https://aur.archlinux.org/packages?K=%s"
        },
        {
            bang: "aw",
            name: "Arch Wiki",
            url: "https://wiki.archlinux.org/index.php?search=%s"
        },
        {
            bang: "w",
            name: "Wikipedia",
            url: "https://es.wikipedia.org/w/index.php?search=%s"
        },
    ]

    function open(url: string): void {
        Quickshell.execDetached(["xdg-open", url]);
    }

    function item(e, text: string): var {
        return {
            name: text,
            sub: `buscar en ${e.name} · !${e.bang}`,
            icon: "",
            abbr: e.bang.toUpperCase(),
            hint: e.name.toUpperCase(),
            run: () => open(e.url.replace("%s", encodeURIComponent(text)))
        };
    }

    function results(query: string): var {
        const q = query.trim();
        if (!q)
            return [];

        // "!yt lofi" con un prefijo conocido → solo ese motor
        const m = q.match(/^!(\S+)\s+(.+)$/);
        if (m) {
            const e = engines.find(x => x.bang === m[1].toLowerCase());
            if (e)
                return [item(e, m[2])];
        }

        // Sin prefijo (o desconocido): el texto en todos los motores
        const text = q.replace(/^!\S*\s*/, "");
        if (!text)
            return [];

        const out = [];
        // Parece una dirección → primero, abrirla tal cual
        if (/^(https?:\/\/)?[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(text)) {
            out.push({
                name: text,
                sub: "abrir dirección",
                icon: "",
                abbr: "↗",
                hint: "URL",
                run: () => open(text.startsWith("http") ? text : "https://" + text)
            });
        }
        return out.concat(engines.map(e => item(e, text)));
    }
}
