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

    Variants {
        model: Quickshell.screens
        Bar {
            visible: root.barVisible
        }
    }

    Launcher {}

    Component.onCompleted: console.log("CALC:", Calc.evaluate("=2^10/4"), Calc.evaluate("sqrt(2)*pi"), Calc.evaluate("hola"), "| CMD:", Commands.search("rein").map(c => c.name))

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
}
