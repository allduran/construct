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
import qs.modules.clipboard
import qs.modules.emoji
import qs.modules.capture
import qs.modules.media
import qs.modules.wallpaper
import qs.modules.color
import qs.modules.settings
import qs.common
import qs.components
import qs.services

ShellRoot {
    id: root
    property bool barVisible: true
    // Fuerza a cargar los ajustes guardados al arrancar
    readonly property bool settingsLoaded: Settings.loaded
    readonly property bool gameReady: GameMode.active
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

    // Selector ENFOQUE: uno por monitor (como la barra)
    Variants {
        model: Quickshell.screens
        Focus {}
    }

    Variants {
        model: Quickshell.screens
        Background {}
    }

    Launcher {}
    ControlCenter {}
    LockScreen {}
    SessionMenu {}
    NotificationPopups {}
    Osd {
        id: osd
    }

    Buffer {}
    Glyphs {}
    Reticle {}
    MediaPanel {}
    Signal {}
    ColorToast {}
    SettingsWindow {}

    // duran ipc color_pick
    IpcHandler {
        target: "color"
        function pick(): void {
            Colors.pick();
        }
    }

    // duran ipc emoji      → retícula (Tab dentro: GLIFOS completo)
    // duran ipc emoji_all  → GLIFOS directamente
    IpcHandler {
        target: "emoji"
        function toggle(): void {
            const open = !ShellState.emojiWheelOpen;
            ShellState.closeAll();
            ShellState.emojiWheelOpen = open;
        }
        function all(): void {
            const open = !ShellState.emojiOpen;
            ShellState.closeAll();
            ShellState.emojiOpen = open;
        }
    }

    // duran ipc mode / mode_set
    IpcHandler {
        target: "mode"
        function toggle(): void {
            GameMode.toggle();
        }
        // Acepta los nombres de velvet y ancient: game / dire → juego; el resto → normal
        function set(m: string): void {
            GameMode.set(["game", "dire", "juego"].includes(m));
        }
    }

    // duran ipc wallpaper (el selector llega en el 12b)
    IpcHandler {
        target: "wallpaper"
        function setFilter(f: int): void {
            Wallpapers.filter = f;
        }
        function setIntensity(k: real): void {
            Wallpapers.intensity = k;
        }
        function next(): void {
            const l = Wallpapers.list;
            const i = l.findIndex(w => w.path === Wallpapers.current);
            if (l.length)
                Wallpapers.current = l[(i + 1) % l.length].path;
        }
        function toggle(): void {
            const open = !ShellState.wallpaperOpen;
            ShellState.closeAll();
            ShellState.wallpaperOpen = open;
        }
    }

    // duran ipc clipboard
    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            const open = !ShellState.clipboardOpen;
            ShellState.closeAll();
            ShellState.clipboardOpen = open;
        }
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
            const open = !Session.menuOpen;
            ShellState.closeAll();
            Session.menuOpen = open;
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
            const open = !ShellState.launcherOpen;
            ShellState.closeAll();
            ShellState.launcherOpen = open;
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
            const open = !ShellState.controlOpen;
            ShellState.closeAll();
            ShellState.controlOpen = open;
        }
    }

    // duran ipc shot_* / rec_*
    IpcHandler {
        target: "capture"
        function screen(): void {
            Capture.run("screen");
        }
        function region(): void {
            Capture.startSelect("area");
        }
        function window(): void {
            Capture.run("window", "");
        }
        function record(): void {
            Capture.startSelect("record-area");
        }
        function recordScreen(): void {
            Capture.run("record-screen");
        }
        function recordSound(): void {
            Capture.run("record-sound");
        }
    }

    // duran ipc media_*
    IpcHandler {
        target: "media"
        function toggle(): void {
            Media.toggle();
        }
        function next(): void {
            Media.next();
        }
        function previous(): void {
            Media.previous();
        }
        function stop(): void {
            Media.stop();
        }
    }
}
