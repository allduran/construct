#!/usr/bin/env bash
# construct — hook de instalación: lo que no son paquetes
# (servicios, grupos, carpetas de estado…). Se ejecuta desde la carpeta del shell.
set -euo pipefail

echo "construct: install ok"

# construct dibuja el fondo: fuera otros gestores de fondo
for p in hyprpaper swww-daemon swaybg; do
    systemctl --user disable --now "$p.service" 2>/dev/null || true
    pkill -x "$p" 2>/dev/null || true
done