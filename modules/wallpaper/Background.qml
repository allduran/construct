import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.components
import qs.services

// Fondo del escritorio (uno por monitor), detrás de todas las ventanas.
// Al cambiar de fondo, fundido entre dos capas.
PanelWindow {
    id: bg
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "construct-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Theme.bg

    property bool flip: false

    // Dos capas: la nueva entra encima mientras la vieja se queda debajo
    WallImage {
        id: a
        anchors.fill: parent
        filter: Wallpapers.filter
        intensity: Wallpapers.intensity
        opacity: bg.flip ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }
    }
    WallImage {
        id: b
        anchors.fill: parent
        filter: Wallpapers.filter
        intensity: Wallpapers.intensity
        opacity: bg.flip ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }
    }

    function show(path: string) {
        if (!path)
            return;
        const front = flip ? b : a;
        if (String(front.source) === "file://" + path)
            return;
        const back = flip ? a : b;
        back.source = "file://" + path;
        flip = !flip;
    }

    Component.onCompleted: {
        a.source = Wallpapers.current ? "file://" + Wallpapers.current : "";
    }
    Connections {
        target: Wallpapers
        function onCurrentChanged() {
            bg.show(Wallpapers.current);
        }
    }
}
