pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Apps instaladas (.desktop), búsqueda con puntuación e historial de uso.
// Uso: Apps.search("te"), Apps.launch(app), Apps.recent(4)
Singleton {
    id: root

    // Apps visibles, ordenadas por nombre
    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    // { "<id>": { count: 12, last: 1793043656000 } }
    readonly property var usage: store_.usage

    // Convierte cualquier lista de Qt (o texto "A;B;") en un array JS normal
    function toArray(x): var {
        if (!x)
            return [];
        if (typeof x === "string")
            return x.split(";").filter(s => s !== "");
        const out = [];
        for (let i = 0; i < x.length; i++)
            out.push(String(x[i]));
        return out;
    }

    // Ruta del icono, con uno genérico si la app no tiene
    function icon(app): string {
        return Quickshell.iconPath(app ? app.icon : "", "application-x-executable");
    }

    // ── Búsqueda ───────────────────────────────────────
    function search(query: string): var {
        const q = query.trim().toLowerCase();
        if (!q)   // sin texto: las más usadas primero
            return [...all].sort((a, b) => uses(b) - uses(a) || a.name.localeCompare(b.name));

        return all.map(app => ({
                    app,
                    s: score(app, q)
                })).filter(r => r.s > 0).sort((x, y) => y.s - x.s || x.app.name.localeCompare(y.app.name)).map(r => r.app);
    }

    function score(app, q: string): int {
        const name = app.name.toLowerCase();
        const extra = [app.genericName || "", app.comment || "", ...toArray(app.keywords)].join(" ").toLowerCase();
        let s;
        if (name.startsWith(q))
            s = 100;
        else
        // "fir" → Firefox
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            s = 80;
        else
        // "code" → VS Code
        if (name.includes(q))
            s = 60;
        else if (extra.includes(q))
            s = 40;
        else
        // "browser" → Firefox
        if (fuzzy(name, q))
            s = 20;
        else
            // "ktty" → kitty
            return 0;
        return s + Math.min(15, uses(app));   // pequeño empujón a las que más usas
    }

    // Todas las letras de q aparecen en orden dentro de text
    function fuzzy(text: string, q: string): bool {
        let i = 0;
        for (const c of text)
            if (c === q[i] && ++i === q.length)
                return true;
        return false;
    }

    function uses(app): int {
        return usage[app.id]?.count ?? 0;
    }

    // ── Lanzar y registrar ─────────────────────────────
    function launch(app): void {
        app.execute();
        const prev = usage[app.id] ?? {
            count: 0,
            last: 0
        };
        // Objeto nuevo (no mutar): así la propiedad avisa del cambio
        store_.usage = Object.assign({}, usage, {
            [app.id]: {
                count: prev.count + 1,
                last: Date.now()
            }
        });
        store.writeAdapter();
    }

    // Las n últimas usadas: [{ app, last }]
    function recent(n: int): var {
        return all.filter(a => usage[a.id]).map(a => ({
                    app: a,
                    last: usage[a.id].last
                })).sort((x, y) => y.last - x.last).slice(0, n);
    }

    // ── Persistencia: ~/.local/state/quickshell/by-shell/…/apps.json ──
    FileView {
        id: store
        path: Quickshell.statePath("apps.json")
        // Primera vez: el archivo no existe → lo creamos vacío
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store_
            property var usage: ({})
        }
    }
}
