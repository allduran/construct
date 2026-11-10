import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.common
import qs.components

// Bandeja del sistema. Clic: abrir app · Central: acción secundaria · Derecho: menú propio (como velvet).
Row {
    id: root
    spacing: 10

    required property var window          // ventana de la barra: el menú se ancla a ella

    // ── Menú abierto ──
    property var openItem: null           // app cuyo menú se muestra
    property var menuStack: []            // submenús abiertos (el último es el visible)
    property real menuX: 0                // x del icono en la ventana de la barra

    function openMenu(item, x: real) {
        menuStack = [];
        menuX = x;
        openItem = item;
    }
    function closeMenu() {
        openItem = null;
        menuStack = [];
    }

    // "_Abrir" → "Abrir" (los guiones bajos son atajos de teclado de GTK)
    function clean(t: string): string {
        return (t || "").replace(/_([^_])/g, "$1").replace(/__/g, "_");
    }
    function nameOf(item): string {
        return item.title || (item.tooltipTitle || "").split("\n")[0] || item.id;
    }

    // Iconos "nombre?path=/ruta" que mandan algunas apps (Steam, Discord…)
    function iconFor(icon: string): string {
        if (!icon.includes("?path="))
            return icon;
        const [name, path] = icon.split("?path=");
        return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
    }

    // Lee las entradas del menú (o del submenú abierto)
    QsMenuOpener {
        id: opener
        menu: root.menuStack.length ? root.menuStack[root.menuStack.length - 1] : root.openItem?.menu ?? null
    }

    // ── Iconos ──
    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: slot
            required property SystemTrayItem modelData

            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onClicked: e => {
                const x = slot.mapToItem(null, 0, 0).x;
                if (e.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (e.button === Qt.RightButton || modelData.onlyMenu) {
                    if (!modelData.hasMenu)
                        return;
                    if (root.openItem === modelData)
                        root.closeMenu();
                        // segundo clic: cerrar
                    else
                        root.openMenu(modelData, x);
                } else {
                    root.closeMenu();
                    modelData.activate();
                }
            }
            onWheel: w => modelData.scroll(w.angleDelta.y / 120, false)

            IconImage {
                anchors.fill: parent
                source: root.iconFor(slot.modelData.icon)
                // Monocromo fósforo; color original al pasar el ratón o con su menú abierto
                layer.enabled: !slot.containsMouse && root.openItem !== slot.modelData
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: Theme.accent
                }
            }
        }
    }

    // ── Menú (ventana emergente anclada a la barra) ──
    PopupWindow {
        id: popup
        visible: root.openItem !== null
        anchor.window: root.window
        anchor.rect.x: Math.max(0, Math.min(root.window.width - implicitWidth, root.menuX - 12))
        anchor.rect.y: root.window.height + 8
        grabFocus: true                    // clic fuera = se cierra
        implicitWidth: 300
        implicitHeight: menuCol.implicitHeight + 24
        color: "transparent"

        onVisibleChanged: if (!visible)
            root.closeMenu()   // cerrado por clic fuera

        CutPanel {
            anchors.fill: parent
            padding: 12
            cutTopRight: 0
            cutBottomLeft: 14
            color: Qt.alpha(Theme.bg, 0.96)
            borderColor: Theme.accentDim

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.closeMenu()
            }

            Column {
                id: menuCol
                width: popup.implicitWidth - 24
                spacing: 2

                // Cabecera: nombre de la app, o "←" para volver del submenú
                Item {
                    width: parent.width
                    height: 30

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.openItem ? (root.menuStack.length ? "← " : "") + root.nameOf(root.openItem).toUpperCase() : ""
                        color: Theme.accent
                        font.family: Theme.fontDisplay
                        font.pixelSize: 12
                        font.letterSpacing: Theme.tracking
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.menuStack.length > 0
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.menuStack = root.menuStack.slice(0, -1)
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.accentFaint
                }

                Repeater {
                    model: opener.children

                    delegate: Item {
                        id: entry
                        required property QsMenuEntry modelData
                        readonly property bool isCheck: modelData.buttonType === QsMenuButtonType.CheckBox
                        readonly property bool isRadio: modelData.buttonType === QsMenuButtonType.RadioButton
                        readonly property bool checked: modelData.checkState === Qt.Checked

                        width: menuCol.width
                        height: modelData.isSeparator ? 9 : 34

                        // Separador
                        Rectangle {
                            visible: entry.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 1
                            color: Theme.accentFaint
                        }

                        // Fila
                        Rectangle {
                            visible: !entry.modelData.isSeparator
                            anchors.fill: parent
                            color: rowArea.containsMouse && entry.modelData.enabled ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                            opacity: entry.modelData.enabled ? 1 : 0.4

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 8
                                spacing: 10

                                // Casilla / radio / icono / hueco
                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 16

                                    Text {
                                        visible: entry.isCheck || entry.isRadio
                                        anchors.centerIn: parent
                                        text: entry.isRadio ? (entry.checked ? "●" : "○") : (entry.checked ? "■" : "□")
                                        color: entry.checked ? Theme.accent : Theme.textDim
                                        font.pixelSize: 12
                                    }
                                    IconImage {
                                        visible: !entry.isCheck && !entry.isRadio && entry.modelData.icon !== ""
                                        anchors.fill: parent
                                        source: entry.modelData.icon
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: menuCol.width - 16 - 10 - 8 - 24
                                    elide: Text.ElideRight
                                    text: root.clean(entry.modelData.text)
                                    color: rowArea.containsMouse ? Theme.textBright : Theme.text
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                }
                            }

                            Text {
                                visible: entry.modelData.hasChildren
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "›"
                                color: Theme.accent
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: entry.modelData.enabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (entry.modelData.hasChildren) {
                                        root.menuStack = [...root.menuStack, entry.modelData];
                                        return;
                                    }
                                    entry.modelData.triggered();
                                    root.closeMenu();
                                }
                            }
                        }
                    }
                }

                // Menú vacío (algunas apps tardan un instante en mandarlo)
                Text {
                    visible: opener.children.values.length === 0
                    topPadding: 6
                    text: "sin opciones_"
                    color: Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSm
                }
            }
        }
    }
}
