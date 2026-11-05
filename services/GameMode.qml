pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.common

// Modo juego: Hyprland sin efectos, rendimiento, gamemoded, no molestar y sin bloqueo por inactividad.
Singleton {
    id: root

    readonly property bool active: Theme.gameMode
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/construct"

    // Lo que había antes de entrar, para dejarlo igual al salir
    property int prevProfile: PowerProfile.Balanced
    property bool prevDnd: false

    function toggle(): void {
        set(!Theme.gameMode);
    }

    function set(on: bool): void {
        if (on === Theme.gameMode)
            return;
        if (on) {
            prevProfile = PowerProfiles.profile;
            prevDnd = Toggles.dnd;
        }
        Theme.gameMode = on;

        // Energía
        if (on && PowerProfiles.hasPerformanceProfile)
            PowerProfiles.profile = PowerProfile.Performance;
        else if (!on)
            PowerProfiles.profile = prevProfile;

        // No molestar
        Toggles.dnd = on ? true : prevDnd;

        // gamemoded (Feral): optimiza la CPU para lo que lances con gamemoderun / Steam
        Quickshell.execDetached(["sh", "-c", on ? "pgrep -f '^gamemoded -r' >/dev/null || setsid gamemoded -r >/dev/null 2>&1 &" : "pkill -f '^gamemoded -r' || true"]);

        // Hyprland: lo lee hypr/shell.lua al recargar
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && echo "$2" > "$1/game" && hyprctl reload >/dev/null', "sh", stateDir, on ? "1" : "0"]);
    }

    // Mientras dure: Hyprland/hypridle no apagan ni bloquean la pantalla (juego con mando)
    Process {
        running: Theme.gameMode
        command: ["systemd-inhibit", "--what=idle", "--who=construct", "--why=Modo juego", "sleep", "infinity"]
    }

    // Al arrancar construct, el modo juego empieza apagado: si Hyprland se quedó en modo juego, se restaura
    Component.onCompleted: Quickshell.execDetached(["sh", "-c", 'f="$1/game"; [ "$(cat "$f" 2>/dev/null)" = 1 ] && echo 0 > "$f" && hyprctl reload >/dev/null; true', "sh", stateDir])
}
