pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Interruptores rápidos: Wi-Fi, Bluetooth, No molestar, luz nocturna
Singleton {
    id: root

    property bool wifi: false
    property bool bluetooth: false
    property bool dnd: false            // No molestar (solo dentro del shell)
    property bool night: false
    property int nightTemp: 4500        // K de la luz nocturna

    function toggleWifi() {
        root.wifi = !root.wifi;
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifi ? "on" : "off"]);
    }
    function toggleBluetooth() {
        root.bluetooth = !root.bluetooth;
        Quickshell.execDetached(["bluetoothctl", "power", root.bluetooth ? "on" : "off"]);
    }
    function toggleDnd() {
        root.dnd = !root.dnd;
    }
    function toggleNight() {
        root.night = !root.night;
        if (root.night)
            Quickshell.execDetached(["hyprsunset", "-t", String(root.nightTemp)]);
        else
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
    }

    // Lee el estado real cada 5 s (por si se cambia desde fuera)
    Process {
        id: poll
        command: ["sh", "-c", "nmcli radio wifi; " + "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off; " + "pgrep -x hyprsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n");
                root.wifi = l[0] === "enabled";
                root.bluetooth = l[1] === "on";
                root.night = l[2] === "on";
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }
}
