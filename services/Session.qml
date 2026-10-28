pragma Singleton

import Quickshell
import QtQuick

// Acciones de sesión: un solo sitio para Armería, menú de sesión y pantalla de bloqueo
Singleton {
    property bool menuOpen: false

    function lock() {
        Lock.lock();
    }
    function suspend() {
        Lock.lock();
        Quickshell.execDetached(["systemctl", "suspend"]);
    }   // bloquea antes de dormir
    function logout() {
        Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")]);
    }
    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }
    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
