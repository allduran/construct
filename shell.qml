// construct — shell de Quickshell creado con 'duran new'
import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.bar
import qs.modules.launcher
import qs.common
import qs.components
import qs.services

ShellRoot {
    id: root
    property bool barVisible: true
    // Fuerza a cargar los ajustes guardados al arrancar
    readonly property bool settingsLoaded: Settings.loaded
    // Crea estos servicios al arrancar (si no, la primera tecla se pierde
    // mientras Pipewire / brightnessctl se inicializan)
    readonly property bool audioReady: Audio.ready
    readonly property bool brightnessReady: Brightness.available

    Variants {
        model: Quickshell.screens
        Bar {
            visible: root.barVisible
        }
    }

    Launcher {}

    // duran ipc launcher
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            ShellState.launcherOpen = !ShellState.launcherOpen;
        }
    }

    // duran ipc bar
    IpcHandler {
        target: "bar"
        function toggle(): void {
            root.barVisible = !root.barVisible;
        }
    }

    IpcHandler {
        target: "audio"
        function up(): void {
            console.log("IPC audio.up · ready:", Audio.ready, "· sink:", Audio.sink, "· vol:", Audio.volume);
            Audio.up();
        }
        function down(): void {
            console.log("IPC audio.down · ready:", Audio.ready, "· vol:", Audio.volume);
            Audio.down();
        }
        function mute(): void {
            Audio.toggleMute();
        }
    }

    IpcHandler {
        target: "brightness"
        function up(): void {
            console.log("IPC bright.up · available:", Brightness.available, "· value:", Brightness.value);
            Brightness.up();
        }
        function down(): void {
            Brightness.down();
        }
    }
}
