import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.common
import qs.components

// Espacios de trabajo de Hyprland como chips con esquina recortada.
Row {
    id: root
    spacing: 6

    // Monitor de esta barra: cada barra resalta el espacio activo de SU pantalla
    required property HyprlandMonitor monitor

    // Mínimo 6; si existe un espacio mayor (p. ej. el 8), se amplía hasta él.
    // Los especiales (scratchpad) tienen id negativo y se ignoran.
    readonly property int count: Math.max(6, ...Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id))

    Repeater {
        model: root.count

        delegate: CutPanel {
            id: chip
            required property int index

            readonly property int wsId: index + 1
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            readonly property bool active: root.monitor?.activeWorkspace?.id === wsId
            readonly property bool urgent: ws?.urgent ?? false
            // Hyprland solo mantiene vivos los espacios con ventanas (o el activo)
            readonly property bool occupied: ws !== null && (ws.toplevels?.values.length ?? 1) > 0

            width: 38
            height: 30
            padding: 0
            cutTopRight: Theme.cutSmall

            color: active ? Theme.accent : urgent ? Qt.alpha(Theme.magenta, 0.15) : "transparent"
            borderColor: active ? Theme.accent : urgent ? Theme.magenta : occupied ? Theme.accentDim : Qt.alpha(Theme.textDim, 0.3)

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                anchors.centerIn: parent
                text: String(chip.wsId).padStart(2, "0")   // 1 → "01"
                color: chip.active ? Theme.accentFg : chip.urgent ? "#ff7ab0" : chip.occupied ? Theme.text : Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSm
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${chip.wsId}" })`)
            }
        }
    }

    // Rueda sobre los chips: espacio anterior / siguiente en este monitor
    WheelHandler {
        onWheel: e => Hyprland.dispatch(`hl.dsp.focus({ workspace = "${e.angleDelta.y > 0 ? "m-1" : "m+1"}" })`)
    }
}
