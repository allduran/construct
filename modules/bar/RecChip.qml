import QtQuick
import qs.common
import qs.components
import qs.services

// ● REC 00:42 — visible mientras wf-recorder graba. Clic: parar.
CutPanel {
    id: chip
    visible: Capture.recording
    padding: 14
    cutTopRight: 0
    color: Qt.alpha(Theme.magenta, 0.14)
    borderColor: Theme.magenta

    property int elapsed: 0     // segundos

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: chip.visible
        onTriggered: chip.elapsed = Math.max(0, Math.floor((Date.now() - Capture.recStart) / 1000))
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: Theme.magenta
            SequentialAnimation on opacity {
                running: chip.visible
                loops: Animation.Infinite
                PropertyAction {
                    value: 1
                }
                PauseAnimation {
                    duration: 500
                }
                PropertyAction {
                    value: 0.2
                }
                PauseAnimation {
                    duration: 500
                }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "REC " + String(Math.floor(chip.elapsed / 60)).padStart(2, "0") + ":" + String(chip.elapsed % 60).padStart(2, "0")
            color: "#ff7ab0"
            font.family: Theme.fontDisplay
            font.pixelSize: 13
            font.letterSpacing: 2
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Cualquier modo record* para la grabación en marcha (lo hace capture.sh)
        onClicked: Capture.run("record-screen")
    }
}
