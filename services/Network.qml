pragma Singleton
import Quickshell
import Quickshell.Networking
import QtQuick

// Red WiFi activa según NetworkManager, por D-Bus (Quickshell.Networking): sin procesos.
Singleton {
    id: root

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var network: device?.networks.values.find(n => n.connected) ?? null

    readonly property string ssid: network?.name ?? ""
    readonly property int signal: Math.round((network?.signalStrength ?? 0) * 100)   // 0–100
    readonly property bool connected: ssid !== ""
}
