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
        }
    }

    // Disco → Theme (una sola vez, al arrancar)
    function apply(): void {
        if (loaded)
            return;
        Theme.rain = adapter.rain;
        Theme.scanlines = adapter.scanlines;
        Theme.glitch = adapter.glitch;
        loaded = true;
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
