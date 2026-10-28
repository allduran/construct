import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.common
import qs.components
import qs.services

// OSD de volumen y brillo. Se muestra con show("volume") / show("brightness").
PanelWindow {
    id: osd

    property string kind: "volume"
    property bool shown: false
    visible: shown || fade.running          // sigue visible mientras se desvanece

    function show(k: string): void {
        if (ShellState.controlOpen)
            // con el panel abierto ya se ven los sliders
            return;
        kind = k;
        fade.stop();
        if (!shown)
            enter.restart();
        shown = true;
        hideTimer.restart();                 // cada pulsación alarga el tiempo
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        bottom: true
    }                // solo abajo → centrado en horizontal
    margins {
        bottom: 80
    }
    implicitWidth: 420
    implicitHeight: 76
    color: "transparent"

    readonly property bool isVol: kind === "volume"
    readonly property real value: isVol ? (Audio.muted ? 0 : Audio.volume) : Brightness.value
    readonly property color tone: isVol ? (Audio.muted ? Theme.magenta : Theme.accent) : Theme.cyan
    readonly property string label: isVol ? (Audio.muted ? "VOLUMEN · SILENCIO" : "VOLUMEN") : "BRILLO"

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: {
            osd.shown = false;
            fade.restart();
        }
    }

    CutPanel {
        id: panel
        anchors.fill: parent
        padding: 16
        cutTopRight: Theme.cut
        cutBottomLeft: Theme.cut
        color: Qt.alpha(Theme.bg, 0.94)
        borderColor: osd.tone
        transform: Translate {
            id: shift
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 8

            Item {
                width: parent.width
                height: lbl.implicitHeight

                Text {
                    id: lbl
                    text: osd.label
                    color: osd.tone
                    font.family: Theme.fontDisplay
                    font.pixelSize: 13
                    font.letterSpacing: Theme.tracking
                }
                Text {
                    anchors.right: parent.right
                    anchors.baseline: lbl.baseline
                    text: Math.round(osd.value * 100) + "%"
                    color: Theme.textBright
                    font.family: Theme.fontDisplay
                    font.pixelSize: 16
                }
            }

            Row {
                width: parent.width
                spacing: 3
                Repeater {
                    model: 20
                    Rectangle {
                        required property int index
                        width: (parent.width - 19 * 3) / 20
                        height: 14
                        color: index < Math.round(osd.value * 20) ? osd.tone : Theme.track
                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }
                    }
                }
            }
        }
    }

    // Entrada: parpadeo + sube un poco
    ParallelAnimation {
        id: enter
        SequentialAnimation {
            PropertyAction {
                target: panel
                property: "opacity"
                value: 0.3
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: panel
                property: "opacity"
                value: 0.9
            }
            PauseAnimation {
                duration: 40
            }
            NumberAnimation {
                target: panel
                property: "opacity"
                to: 1
                duration: 80
            }
        }
        NumberAnimation {
            target: shift
            property: "y"
            from: 16
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    // Salida: fundido
    NumberAnimation {
        id: fade
        target: panel
        property: "opacity"
        to: 0
        duration: 180
    }
}
