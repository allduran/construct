import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.common
import qs.components
import qs.services

// MUESTRA //: tarjeta con el color recién cogido, sus formatos y la paleta.
PanelWindow {
    id: toast

    property string hex: ""
    property string copied: ""          // formato copiado hace un momento
    property bool shown: false
    visible: shown

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "construct-color"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None    // no roba el foco: sigues trabajando
    exclusionMode: ExclusionMode.Ignore
    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 16
        right: 16
    }
    implicitWidth: 420
    implicitHeight: card.implicitHeight
    color: "transparent"

    function show(h: string) {
        hex = h;
        copied = "HEX";
        shown = true;
        hide.restart();
        enter.restart();
    }

    Connections {
        target: Colors
        function onPicked(h) {
            toast.show(h);
        }
    }

    Timer {
        id: hide
        interval: 6000
        running: toast.shown && !hov.hovered
        onTriggered: toast.shown = false
    }
    Timer {
        id: copiedReset
        interval: 1200
        onTriggered: toast.copied = ""
    }

    HoverHandler {
        id: hov
    }

    CutPanel {
        id: card
        width: parent.width
        padding: 16
        cutTopRight: 0
        cutTopLeft: 18
        color: Qt.alpha(Theme.bg, 0.95)
        borderColor: Theme.accentDim
        transform: Translate {
            id: shift
        }

        Column {
            width: card.width - card.padding * 2
            spacing: 12

            // Cabecera
            Item {
                width: parent.width
                height: 20
                Text {
                    text: "MUESTRA //"
                    color: Theme.accent
                    font.family: Theme.fontDisplay
                    font.pixelSize: 13
                    font.letterSpacing: Theme.tracking
                }
                Text {
                    anchors.right: parent.right
                    text: "✕"
                    color: closeArea.containsMouse ? Theme.textBright : Theme.textDim
                    font.pixelSize: 13
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toast.shown = false
                    }
                }
            }

            // Muestra con el HEX encima
            Rectangle {
                width: parent.width
                height: 90
                color: toast.hex || "transparent"
                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 12
                    text: toast.hex.toUpperCase()
                    color: Colors.isLight(toast.hex || "#000000") ? "#020403" : "#eafff2"
                    font.family: Theme.fontDisplay
                    font.pixelSize: 26
                    font.letterSpacing: 2
                }
            }

            // Formatos: clic = copiar ese
            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: toast.hex ? Colors.formats(toast.hex) : []
                    delegate: CutPanel {
                        id: fmt
                        required property var modelData
                        readonly property bool justCopied: toast.copied === modelData.k
                        width: (card.width - card.padding * 2 - 6) / 2
                        padding: 10
                        cutTopRight: 0
                        scanlines: false
                        color: fmtArea.containsMouse ? Qt.alpha(Theme.accent, 0.1) : "transparent"
                        borderColor: justCopied ? Theme.accent : Theme.accentFaint

                        Column {
                            spacing: 3
                            Text {
                                text: fmt.justCopied ? fmt.modelData.k + " · COPIADO" : fmt.modelData.k
                                color: fmt.justCopied ? Theme.accent : Theme.textDim
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fsXs
                                font.letterSpacing: 1.4
                            }
                            Text {
                                width: fmt.width - 20
                                elide: Text.ElideRight
                                text: fmt.modelData.v
                                color: Theme.textBright
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                            }
                        }
                        MouseArea {
                            id: fmtArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Colors.copy(fmt.modelData.v);
                                toast.copied = fmt.modelData.k;
                                copiedReset.restart();
                            }
                        }
                    }
                }
            }

            // Paleta: clic = verlo y copiarlo · clic derecho = quitarlo
            Column {
                width: parent.width
                spacing: 6
                visible: Colors.palette.length > 1

                Text {
                    text: `PALETA · ${Colors.palette.length}`
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsXs
                    font.letterSpacing: 1.4
                }
                Flow {
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: Colors.palette
                        delegate: Rectangle {
                            id: sw
                            required property string modelData
                            width: (card.width - card.padding * 2 - 11 * 4) / 12
                            height: width
                            color: modelData
                            border.width: modelData === toast.hex ? 2 : 1
                            border.color: modelData === toast.hex ? Theme.accent : Qt.alpha(Theme.textDim, 0.3)
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: e => {
                                    if (e.button === Qt.RightButton) {
                                        Colors.remove(sw.modelData);
                                        return;
                                    }
                                    toast.hex = sw.modelData;
                                    Colors.copy(sw.modelData);
                                    toast.copied = "HEX";
                                    copiedReset.restart();
                                }
                            }
                        }
                    }
                }
            }

            // Acciones
            Row {
                spacing: 6
                CutPanel {
                    width: pickText.implicitWidth + 28
                    height: 36
                    padding: 0
                    cutTopRight: 0
                    scanlines: false
                    color: Theme.accent
                    borderColor: Theme.accent
                    Text {
                        id: pickText
                        anchors.centerIn: parent
                        text: "OTRO COLOR"
                        color: Theme.accentFg
                        font.family: Theme.fontDisplay
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            toast.shown = false;
                            Colors.pick();
                        }
                    }
                }
                CutPanel {
                    visible: Colors.palette.length > 0
                    width: gplText.implicitWidth + 28
                    height: 36
                    padding: 0
                    cutTopRight: 0
                    scanlines: false
                    color: "transparent"
                    borderColor: Theme.accentDim
                    Text {
                        id: gplText
                        anchors.centerIn: parent
                        text: "EXPORTAR .gpl"
                        color: Theme.text
                        font.family: Theme.fontDisplay
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Colors.exportGpl()
                    }
                }
            }
        }
    }

    // Entrada: sube desde abajo con parpadeo
    ParallelAnimation {
        id: enter
        NumberAnimation {
            target: shift
            property: "y"
            from: 30
            to: 0
            duration: 220
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            PropertyAction {
                target: card
                property: "opacity"
                value: 0.3
            }
            PauseAnimation {
                duration: 50
            }
            PropertyAction {
                target: card
                property: "opacity"
                value: 0.9
            }
            PauseAnimation {
                duration: 40
            }
            NumberAnimation {
                target: card
                property: "opacity"
                to: 1
                duration: 100
            }
        }
    }
}
