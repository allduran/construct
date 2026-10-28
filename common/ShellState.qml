pragma Singleton
import Quickshell
import QtQuick

// Estado global del shell: qué paneles están abiertos.
Singleton {
    property bool launcherOpen: false
    property bool controlOpen: false
}
