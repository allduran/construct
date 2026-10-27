pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Estadísticas del sistema leídas de /proc cada 'interval' ms.
// Uso: import qs.services  →  SysStats.cpu, SysStats.mem, SysStats.netDown…
Singleton {
    id: root

    property int interval: 2000

    property real cpu: 0          // % 0–100
    property real mem: 0          // % 0–100
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real netDown: 0      // bytes/s
    property real netUp: 0        // bytes/s
    property real gpu: 0              // % 0–100 (Intel, vía RC6)
    property bool gpuAvailable: false

    // Lecturas anteriores: CPU y red se calculan como diferencia entre dos muestras
    property var _cpuPrev: null
    property var _netPrev: null
    property var _gpuPrev: null

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            if (root.gpuAvailable)
                rc6.reload();
        }
    }

    // ── CPU: primera línea de /proc/stat ──
    // cpu  user nice system idle iowait irq softirq steal …
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number);
            const idle = f[3] + f[4];                      // idle + iowait
            const total = f.reduce((a, b) => a + b, 0);
            if (root._cpuPrev) {
                const dt = total - root._cpuPrev.total;
                const di = idle - root._cpuPrev.idle;
                root.cpu = dt > 0 ? (1 - di / dt) * 100 : 0;
            }
            root._cpuPrev = {
                total,
                idle
            };
        }
    }

    // ── Memoria: MemTotal y MemAvailable (en kB) ──
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const get = k => Number(t.match(new RegExp(`^${k}:\\s+(\\d+)`, "m"))?.[1] ?? 0);
            const total = get("MemTotal"), avail = get("MemAvailable");
            root.mem = total ? (total - avail) / total * 100 : 0;
            root.memUsedGiB = (total - avail) / 1048576;
            root.memTotalGiB = total / 1048576;
        }
    }

    // ── Red: suma de todas las interfaces reales ──
    // iface: rx_bytes … (8 campos) tx_bytes …
    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const [name, data] = line.split(":");
                if (!data)
                    continue;
                const n = name.trim();
                if (n === "lo" || /^(veth|docker|br-|virbr)/.test(n))
                    continue;
                const v = data.trim().split(/\s+/).map(Number);
                rx += v[0];
                tx += v[8];
            }
            const now = Date.now();
            if (root._netPrev) {
                const dt = (now - root._netPrev.t) / 1000;
                root.netDown = Math.max(0, (rx - root._netPrev.rx) / dt);
                root.netUp = Math.max(0, (tx - root._netPrev.tx) / dt);
            }
            root._netPrev = {
                rx,
                tx,
                t: now
            };
        }
    }

    // ── GPU Intel: detecta el contador RC6 una vez al arrancar ──
    Process {
        running: true
        command: ["sh", "-c", "find -L /sys/class/drm -maxdepth 4 -path '*/gt/gt0/rc6_residency_ms' 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p) {
                    rc6.path = p;
                    root.gpuAvailable = true;
                }
            }
        }
    }

    // RC6 = ms acumulados con la GPU dormida.
    // Uso = 1 − (ms dormida en el intervalo / ms transcurridos)
    FileView {
        id: rc6
        onLoaded: {
            const ms = Number(text().trim());
            const now = Date.now();
            if (root._gpuPrev) {
                const dt = now - root._gpuPrev.t;
                const idle = ms - root._gpuPrev.ms;
                root.gpu = dt > 0 ? Math.max(0, Math.min(100, (1 - idle / dt) * 100)) : 0;
            }
            root._gpuPrev = {
                ms,
                t: now
            };
        }
    }

    // 1234567 → "1.2M", 84000 → "82K"
    function rate(b: real): string {
        if (b >= 1048576)
            return (b / 1048576).toFixed(1) + "M";
        if (b >= 1024)
            return Math.round(b / 1024) + "K";
        return Math.round(b) + "B";
    }
}
