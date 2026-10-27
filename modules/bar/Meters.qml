import Quickshell.Services.UPower
import QtQuick
import qs.common
import qs.services

// Medidores de la barra: CPU, MEM, red y batería.
Row {
    id: root
    spacing: 18

    // Color según carga: normal → aviso → crítico
    function levelColor(v: real): color {
        return v >= 85 ? Theme.magenta : v >= 60 ? Theme.yellow : Theme.accent;
    }

    // ── Componente interno: etiqueta + valor + barrita ──
    component MeterBar: Column {
        id: m
        required property string label
        required property real value      // 0–100
        property color barColor: Theme.accent

        width: 74
        spacing: 4

        Item {
            width: parent.width
            height: lbl.height
            Text {
                id: lbl
                text: m.label
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSm
            }
            Text {
                anchors.right: parent.right
                text: Math.round(m.value) + "%"
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSm
            }
        }

        // Pista + relleno
        Rectangle {
            width: parent.width
            height: 4
            color: Theme.track

            Rectangle {
                width: parent.width * Math.min(1, m.value / 100)
                height: parent.height
                color: m.barColor
                Behavior on width {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    MeterBar {
        anchors.verticalCenter: parent.verticalCenter
        label: "CPU"
        value: SysStats.cpu
        barColor: root.levelColor(SysStats.cpu)
    }

    MeterBar {
        anchors.verticalCenter: parent.verticalCenter
        label: "MEM"
        value: SysStats.mem
        barColor: root.levelColor(SysStats.mem)
    }

    MeterBar {
        visible: SysStats.gpuAvailable
        anchors.verticalCenter: parent.verticalCenter
        label: "GPU"
        value: SysStats.gpu
        barColor: SysStats.gpu >= 85 ? Theme.magenta : Theme.cyan
    }

    // ── Red ──
    Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.StyledText
        text: `NET <font color="${Theme.text}">↓${SysStats.rate(SysStats.netDown)} ↑${SysStats.rate(SysStats.netUp)}</font>`
        color: Theme.textDim
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsSm
    }

    // ── WiFi ──
    Text {
        readonly property int bars: Math.ceil(Network.signal / 25)   // 0–4
        readonly property string name: Network.ssid.toUpperCase().replace(/&/g, "&amp;").replace(/</g, "&lt;")            // seguro para StyledText

        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.StyledText
        text: Network.connected ? `WIFI <font color="${Theme.text}">${name}</font> <font color="${Theme.accent}">${"▮".repeat(bars)}</font>${"▯".repeat(4 - bars)}` : `WIFI <font color="${Theme.magenta}">SIN SEÑAL</font>`
        color: Theme.textDim
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsSm
    }

    // ── Batería (solo si hay) ──
    Text {
        readonly property var bat: UPower.displayDevice
        readonly property int pct: Math.round((bat?.percentage ?? 0) * 100)
        readonly property bool charging: bat?.state === UPowerDeviceState.Charging || bat?.state === UPowerDeviceState.FullyCharged
        readonly property color valueColor: pct <= 15 && !charging ? Theme.magenta : pct <= 30 && !charging ? Theme.yellow : Theme.accent

        visible: bat?.isLaptopBattery ?? false
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.StyledText
        text: `BAT <font color="${valueColor}">${charging ? "⚡" : ""}${pct}%</font>`
        color: Theme.textDim
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsSm
    }
}
