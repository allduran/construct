pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Servidor de notificaciones de ancient
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values   // todas (escudo)
    readonly property int count: list.length
    property var popups: []                                           // las que se ven ahora
    property var times: ({})                                          // id → hora de llegada (ms)
    property alias tracked: server.trackedNotifications               // modelo vivo (para listas)

    function hidePopup(n) {
        root.popups = root.popups.filter(p => p !== n);
    }

    function hidePopups(ns) {
        root.popups = root.popups.filter(p => !ns.includes(p));
    }

    // Clave de agrupación: la app que la manda
    function appKey(n): string {
        return n.appName || n.desktopEntry || "SISTEMA";
    }

    // [{ app, items }] respetando el orden de 'arr' (la más nueva primero)
    function groupByApp(arr) {
        const byApp = {};
        const out = [];
        for (const n of arr) {
            const k = appKey(n);
            if (!byApp[k]) {
                byApp[k] = {
                    app: k,
                    items: []
                };
                out.push(byApp[k]);
            }
            byApp[k].items.push(n);
        }
        return out;
    }

    // Apps en orden de aparición en 'arr' (la más nueva primero)
    function appsOf(arr): var {
        const out = [];
        for (const n of arr) {
            const k = appKey(n);
            if (!out.includes(k))
                out.push(k);
        }
        return out;
    }

    function clearAll() {
        const all = server.trackedNotifications.values.slice();
        for (const n of all)
            n.dismiss();
        root.popups = [];
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;                                    // guardarla
            root.times[n.id] = Date.now();                        // hora de llegada
            // Con No molestar solo se muestran las críticas (igual se guardan en el escudo)
            const quiet = Toggles.dnd;
            if (!quiet || n.urgency === NotificationUrgency.Critical) {
                // Como mucho 4 apps a la vez (cada una es un grupo)
                const apps = [];
                root.popups = [n].concat(root.popups).filter(p => {
                    const k = root.appKey(p);
                    if (apps.includes(k))
                        return true;
                    if (apps.length >= 4)
                        return false;
                    apps.push(k);
                    return true;
                });
            }
            n.closed.connect(() => {                              // si la cierra la app, quitar el popup
                root.hidePopup(n);
                delete root.times[n.id];
            });
        }
    }
}
