pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.common

// Acciones del sistema para la pestaña COMANDOS del launcher.
// Cada una: abbr (caja del icono), name, sub (detalle), hint (etiqueta), run()
Singleton {
    id: root

    function exec(cmd: var): void {
        Quickshell.execDetached(cmd);
    }

    function onOff(v: bool): string {
        return v ? "activado → desactivar" : "desactivado → activar";
    }

    // Función y no propiedad: así 'sub' de los interruptores refleja el estado actual
    function all(): var {
        return [
            {
                abbr: "雨",
                name: "Lluvia de katakana",
                sub: onOff(Theme.rain),
                hint: "TEMA",
                run: () => Theme.rain = !Theme.rain
            },
            {
                abbr: "▤",
                name: "Scanlines CRT",
                sub: onOff(Theme.scanlines),
                hint: "TEMA",
                run: () => Theme.scanlines = !Theme.scanlines
            },
            {
                abbr: "≋",
                name: "Glitch",
                sub: onOff(Theme.glitch),
                hint: "TEMA",
                run: () => Theme.glitch = !Theme.glitch
            },
            {
                abbr: "RL",
                name: "Recargar construct",
                sub: "duran restart",
                hint: "SHELL",
                run: () => exec(["duran", "restart"])
            },
            {
                abbr: "HY",
                name: "Recargar Hyprland",
                sub: "hyprctl reload",
                hint: "SHELL",
                run: () => exec(["hyprctl", "reload"])
            },
            {
                abbr: "ZZ",
                name: "Suspender",
                sub: "systemctl suspend",
                hint: "SESIÓN",
                run: () => exec(["systemctl", "suspend"])
            },
            {
                abbr: "EX",
                name: "Cerrar sesión",
                sub: "salir de Hyprland",
                hint: "SESIÓN",
                run: () => Hyprland.dispatch("hl.dsp.exit()")
            },
            {
                abbr: "RB",
                name: "Reiniciar",
                sub: "systemctl reboot",
                hint: "SESIÓN",
                run: () => exec(["systemctl", "reboot"])
            },
            {
                abbr: "⏻",
                name: "Apagar",
                sub: "systemctl poweroff",
                hint: "SESIÓN",
                run: () => exec(["systemctl", "poweroff"])
            },
        ];
    }

    function search(query: string): var {
        const q = query.trim().toLowerCase();
        const list = all();
        if (!q)
            return list;
        return list.filter(c => (c.name + " " + c.sub + " " + c.hint).toLowerCase().includes(q));
    }
}
