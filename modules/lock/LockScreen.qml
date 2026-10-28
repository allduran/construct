import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.services

// Bloqueo seguro de Wayland: una superficie por monitor.
WlSessionLock {
    locked: Lock.locked

    WlSessionLockSurface {
        color: Theme.bg
        LockContent {
            anchors.fill: parent
        }
    }
}
