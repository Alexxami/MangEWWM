
#!/usr/bin/env bash

# Script para grabar pantalla en Wayland usando wf-recorder.
# Inicia/para la grabación al ejecutarse (toggle). 
# Se puede enlazar a una combinación de teclas, por ejemplo SUPER+w.
# Por defecto graba toda la pantalla; si se pasa el argumento "--select", 
# permite seleccionar una región con slurp.

# Configuración
OUTPUT_DIR="$HOME/Vídeos"          # Directorio donde se guardarán los vídeos
PID_FILE="/tmp/wf-recorder.pid"    # Archivo para guardar el PID del proceso
SELECTION_FILE="/tmp/wf-recorder-selection" # Archivo para guardar la selección de región

# Comprobar dependencias
if ! command -v wf-recorder &>/dev/null; then
    echo "Error: wf-recorder no está instalado." >&2
    echo "Instálalo con tu gestor de paquetes (ej: pacman -S wf-recorder)" >&2
    exit 1
fi

# Si se pide selección, verificar slurp
USE_SELECTION=false
if [[ "$1" == "--select" ]]; then
    if ! command -v slurp &>/dev/null; then
        echo "Error: slurp no está instalado. No se puede seleccionar región." >&2
        echo "Instálalo con tu gestor de paquetes (ej: pacman -S slurp)" >&2
        exit 1
    fi
    USE_SELECTION=true
fi

# Función para iniciar grabación
start_recording() {
    # Crear directorio de salida si no existe
    mkdir -p "$OUTPUT_DIR"
    local filename="grabacion_$(date +%Y%m%d_%H%M%S).mp4"
    local output="$OUTPUT_DIR/$filename"

    local cmd=("wf-recorder" "--file=$output")
    if $USE_SELECTION; then
        # Obtener geometría de selección con slurp
        local geometry
        geometry=$(slurp)
        if [[ -z "$geometry" ]]; then
            echo "Selección cancelada." >&2
            exit 0
        fi
        cmd+=("--geometry=$geometry")
        # Guardar la geometría para posible uso futuro (no necesario, pero útil)
        echo "$geometry" > "$SELECTION_FILE"
    else
        # Si ya existe archivo de selección, lo borramos para evitar confusión
        rm -f "$SELECTION_FILE"
    fi

    # Iniciar grabación en segundo plano
    "${cmd[@]}" &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    echo "Grabación iniciada en $output (PID $pid)"
    # Notificación opcional (requiere libnotify)
    if command -v notify-send &>/dev/null; then
        notify-send "Grabación de pantalla" "Iniciada en $filename"
    fi
}

# Función para detener grabación
stop_recording() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            # Enviar SIGINT para finalizar grabación de forma ordenada
            kill -INT "$pid"
            echo "Deteniendo grabación (PID $pid)..."
            # Esperar a que termine el proceso
            wait "$pid" 2>/dev/null
            echo "Grabación detenida."
            if command -v notify-send &>/dev/null; then
                notify-send "Grabación de pantalla" "Finalizada"
            fi
        else
            echo "El proceso $pid ya no está en ejecución." >&2
        fi
        rm -f "$PID_FILE"
    else
        echo "No hay grabación en curso." >&2
    fi
    # Limpiar archivo de selección
    rm -f "$SELECTION_FILE"
}

# Comprobar si ya hay una grabación activa
if [[ -f "$PID_FILE" ]]; then
    stop_recording
else
    start_recording
fi