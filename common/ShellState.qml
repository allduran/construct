pragma Singleton
import Quickshell
import QtQuick

// Estado global del shell: qué paneles están abiertos.
Singleton {
    property bool launcherOpen: false
    property bool controlOpen: false
    property bool clipboardOpen: false
    property bool emojiOpen: false
    property bool emojiWheelOpen: false
    property bool mediaOpen: false
    property real mediaX: 0          // x del chip de música (para colocar el panel debajo)
    property bool wallpaperOpen: false
    property bool settingsOpen: false

    // Ejecuta fn a los 150 ms. Vive aquí (no en el panel) porque el panel
    // se destruye al cerrarse y se llevaría su propio temporizador.
    Timer {
        id: later
        property var fn: null
        interval: 150
        onTriggered: {
            const f = fn;
            fn = null;
            if (f)
                f();
        }
    }
    function runLater(f): void {
        later.fn = f;
        later.restart();
    }

    // Cierra todos los paneles (al abrir uno, los demás se van)
    function closeAll(): void {
        launcherOpen = false;
        controlOpen = false;
        clipboardOpen = false;
        emojiOpen = false;
        emojiWheelOpen = false;
        mediaOpen = false;
        wallpaperOpen = false;
        settingsOpen = false;
    }
}
