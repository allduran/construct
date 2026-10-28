// construct — shell de Quickshell creado con 'duran new'
import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.bar
import qs.modules.launcher
import qs.modules.control
import qs.modules.lock
import qs.modules.session
import qs.modules.notifications
import qs.modules.osd
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
    LockScreen {}
    SessionMenu {}
    NotificationPopups {}
    Osd {
        id: osd
    }

    // duran ipc notifs_clear
    IpcHandler {
        target: "notifs"
        function clear(): void {
            Notifs.clearAll();
        }
    }

    // duran ipc session
    IpcHandler {
        target: "session"
        function toggle(): void {
            ShellState.launcherOpen = false;
            ShellState.controlOpen = false;
            Session.menuOpen = !Session.menuOpen;
        }
    }

    // duran ipc lock
    IpcHandler {
        target: "lock"
        function lock(): void {
            Lock.lock();
        }
    }

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
            osd.show("volume");
        }
        function down(): void {
            Audio.down();
            osd.show("volume");
        }
        function mute(): void {
            Audio.toggleMute();
            osd.show("volume");
        }
    }

    // duran ipc bright_up / bright_down
    IpcHandler {
        target: "brightness"
        function up(): void {
            Brightness.up();
            osd.show("brightness");
        }
        function down(): void {
            Brightness.down();
            osd.show("brightness");
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
