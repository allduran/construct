// construct — shell de Quickshell creado con 'duran new'
import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.bar
import qs.common
import qs.components

ShellRoot {
    id: root
    property bool barVisible: true

    Variants {
        model: Quickshell.screens
        Bar {
            visible: root.barVisible
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
