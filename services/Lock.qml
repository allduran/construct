pragma Singleton

import Quickshell
import Quickshell.Services.Pam
import QtQuick

// Bloqueo de sesión: estado + comprobación de contraseña con PAM
Singleton {
    id: root

    // ⚠️ Modo prueba: desbloquea solo a los 20 s. Pon false cuando todo funcione.
    readonly property bool testMode: false

    property bool locked: false
    property string password: ""
    property bool busy: false          // comprobando contraseña
    property bool failed: false        // último intento incorrecto

    function lock() {
        password = "";
        failed = false;
        busy = false;
        locked = true;
        if (testMode)
            safety.restart();
    }

    function tryUnlock() {
        if (busy || password === "")
            return;
        busy = true;
        failed = false;
        pam.start();
    }

    // PAM: el mismo sistema que usa el login de Linux
    PamContext {
        id: pam
        config: "login"
        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.password);
        }
        onCompleted: result => {
            root.busy = false;
            root.password = "";
            if (result === PamResult.Success)
                root.locked = false;
            else
                root.failed = true;
        }
    }

    Timer {
        id: safety
        interval: 20000
        onTriggered: root.locked = false
    }
}
