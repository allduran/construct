pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Reproductores MPRIS: cuál está activo y sus controles
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property string preferred: ""        // reproductor elegido a mano en las pestañas

    // Activo: el elegido → el que está sonando → el primero
    readonly property var player: {
        const list = players;
        if (list.length === 0)
            return null;
        const chosen = list.find(p => p.identity === preferred);
        if (chosen)
            return chosen;
        return list.find(p => p.isPlaying) || list[0];
    }

    readonly property bool active: player !== null && player.trackTitle !== ""
    readonly property real progress: player && player.length > 0 ? player.position / player.length : 0

    function fmt(sec) {
        if (!sec || sec < 0)
            return "0:00";
        const s = Math.floor(sec % 60);
        return Math.floor(sec / 60) + ":" + (s < 10 ? "0" : "") + s;
    }

    function toggle() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (player && player.canGoNext)
            player.next();
    }
    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }
    function stop() {
        if (player)
            player.stop();
    }

    function seek(fraction) {
        if (player && player.canSeek && player.length > 0)
            player.position = Math.max(0, Math.min(1, fraction)) * player.length;
    }

    function toggleShuffle() {
        if (player && player.shuffleSupported)
            player.shuffle = !player.shuffle;
    }

    // Ninguno → lista → canción → ninguno
    function cycleLoop() {
        if (!player || !player.loopSupported)
            return;
        player.loopState = player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }

    // MPRIS no avisa de la posición: la pedimos cada segundo mientras suena
    Timer {
        interval: 1000
        repeat: true
        running: root.player !== null && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }
}
