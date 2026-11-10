#!/usr/bin/env bash
# construct — hook de instalación: lo que no son paquetes
# (servicios, grupos, carpetas de estado…). Se ejecuta desde la carpeta del shell.
set -euo pipefail

# Cursor Construct: enlace a ~/.local/share/icons (se actualiza solo con el repo)
shell_dir="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$HOME/.local/share/icons"
ln -sfn "$shell_dir/assets/cursors/Construct" "$HOME/.local/share/icons/Construct"

echo "construct: install ok"

# construct dibuja el fondo: fuera otros gestores de fondo
for p in hyprpaper swww-daemon swaybg; do
    systemctl --user disable --now "$p.service" 2>/dev/null || true
    pkill -x "$p" 2>/dev/null || true
done