// construct — shell de Quickshell creado con 'duran new'
import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.bar
import qs.modules.launcher
import qs.modules.control
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
    ControlCenter {}

    // duran ipc launcher
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            ShellState.controlOpen = false;
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

    // duran ipc volume_up / volume_down / volume_mute
    IpcHandler {
        target: "audio"
        function up(): void {
            Audio.up();
        }
        function down(): void {
            Audio.down();
        }
        function mute(): void {
            Audio.toggleMute();
        }
    }

    // duran ipc bright_up / bright_down
    IpcHandler {
        target: "brightness"
        function up(): void {
            Brightness.up();
        }
        function down(): void {
            Brightness.down();
        }
    }

    // duran ipc settings
    IpcHandler {
        target: "control"
        function toggle(): void {
            ShellState.launcherOpen = false;
            ShellState.controlOpen = !ShellState.controlOpen;
        }
    }
}
