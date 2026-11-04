#!/usr/bin/env bash
# ancient — capturas y grabaciones de pantalla
# Uso:
#   capture.sh screen|record-screen|record-sound [monitor]
#   capture.sh region|record|window                 (selector slurp / ventana activa)
#   capture.sh area|record-area "x,y wxh"           (zona elegida en el selector de ancient)
set -u

mode="${1:-region}"
arg="${2:-}"            # monitor o geometría, según el modo
stamp=$(date +%Y-%m-%d_%H-%M-%S)
shots="$HOME/Pictures/Screenshots"
videos="$HOME/Videos/Recordings"
mkdir -p "$shots" "$videos"

# Selector slurp con estilo ancient (alternativa al selector QML)
SLURP=(slurp -d -w 2 -b '#020403b8' -c '#39ff88ff' -s '#39ff881a' -B '#19e6f033' -F 'JetBrains Mono')

notify() { notify-send -a Construct "$@"; }

# Guarda captura, la copia al portapapeles y avisa. $@ = opciones de grim
shot() {
    local f="$shots/$stamp.png"
    grim "$@" "$f" || exit 1
    wl-copy < "$f"
    notify -i "$f" "Captura guardada" "Copiada al portapapeles · $(basename "$f")"
}

# Grabaciones: si ya hay una en marcha, el mismo atajo la para
if [[ "$mode" == record* ]] && pgrep -x wf-recorder >/dev/null; then
    pkill -INT -x wf-recorder
    notify "Grabación detenida" "Guardada en $videos"
    exit 0
fi

# Graba vídeo. $@ = opciones de wf-recorder
rec() {
    local f="$videos/$stamp.mp4"
    notify "Grabando…" "Pulsa el atajo otra vez para parar"
    exec wf-recorder "$@" -f "$f"
}

case "$mode" in
    screen)        shot ${arg:+-o "$arg"} ;;
    area)          [[ -n "$arg" ]] || exit 1; shot -g "$arg" ;;
    region)        g=$("${SLURP[@]}") || exit 0; shot -g "$g" ;;
    window)        g=$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"') || exit 1
                   shot -g "$g" ;;
    record-area)   [[ -n "$arg" ]] || exit 1; rec -g "$arg" ;;
    record-area-sound) [[ -n "$arg" ]] || exit 1; rec -g "$arg" --audio="$(pactl get-default-sink).monitor" ;;
    record)        g=$("${SLURP[@]}") || exit 0; rec -g "$g" ;;
    record-screen) rec ${arg:+-o "$arg"} ;;
    record-sound)  rec ${arg:+-o "$arg"} --audio="$(pactl get-default-sink).monitor" ;;
    *)             echo "modo desconocido: $mode" >&2; exit 1 ;;
esac