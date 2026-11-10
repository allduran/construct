pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Ajustes guardados entre sesiones (carpeta de estado del shell, settings.json).
// Al cargar se copian a Theme; lo que cambie en Theme se guarda aquí.
Singleton {
    id: root

    property bool loaded: false

    FileView {
        id: file
        path: Quickshell.statePath("settings.json")
        blockLoading: true
        onAdapterUpdated: writeAdapter()          // cualquier cambio → a disco
        onLoaded: root.apply()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
            root.apply();
        }

        JsonAdapter {
            id: adapter
            property bool rain: true
            property bool scanlines: true
            property bool glitch: true
            property string cursorTheme: "Construct"
            property int cursorSize: 24
        }
    }

    // Disco → Theme (una sola vez, al arrancar)
    function apply(): void {
        if (loaded)
            return;
        Theme.rain = adapter.rain;
        Theme.scanlines = adapter.scanlines;
        Theme.glitch = adapter.glitch;
        applyCursor();
        loaded = true;
    }

    readonly property string cursorTheme: adapter.cursorTheme
    readonly property int cursorSize: adapter.cursorSize

    function setCursor(name: string, size: int): void {
        adapter.cursorTheme = name;
        adapter.cursorSize = size;
        applyCursor();
    }

    // Hyprland (y XWayland) al momento + apps GTK
    function applyCursor(): void {
        if (!adapter.cursorTheme)
            return;
        const size = String(adapter.cursorSize);
        Quickshell.execDetached(["hyprctl", "setcursor", adapter.cursorTheme, size]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", adapter.cursorTheme]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", size]);
    }

    Component.onCompleted: Qt.callLater(apply)

    // Theme → disco
    Connections {
        target: Theme
        function onRainChanged() {
            if (root.loaded)
                adapter.rain = Theme.rain;
        }
        function onScanlinesChanged() {
            if (root.loaded)
                adapter.scanlines = Theme.scanlines;
        }
        function onGlitchChanged() {
            if (root.loaded)
                adapter.glitch = Theme.glitch;
        }
    }
}
