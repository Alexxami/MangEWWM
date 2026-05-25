#!/usr/bin/env bash

PROCESS_NAME="auto-stop-bg"
PID_FILE="/tmp/${PROCESS_NAME}.pid"

# Función para matar el proceso guardado en el archivo PID
kill_stored_process() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Matando proceso $PROCESS_NAME (PID $pid)..."
            kill "$pid"
            sleep 1
            # Si aún vive, forzar
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid"
            fi
            rm -f "$PID_FILE"
            echo "Proceso terminado."
        else
            echo "El proceso ya no existe. Limpiando archivo PID."
            rm -f "$PID_FILE"
        fi
    else
        echo "No se encontró archivo PID. ¿El proceso no está corriendo?"
    fi
}

# Comprobar si ya hay un proceso activo mediante el archivo PID
if [[ -f "$PID_FILE" ]]; then
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        echo "El proceso '$PROCESS_NAME' ya está en ejecución (PID $pid). Terminándolo..."
        kill_stored_process
        exit 0
    else
        echo "Archivo PID huérfano encontrado. Eliminándolo..."
        rm -f "$PID_FILE"
    fi
fi

# No existe proceso activo → crear uno nuevo
echo "Iniciando proceso '$PROCESS_NAME' en segundo plano..."

# Lanzar un proceso que haga algo útil (bucle ligero)
(
    # Bucle que se ejecuta mientras el script padre quiera
    while true; do
        sleep 10
    done
) &

new_pid=$!
echo "$new_pid" > "$PID_FILE"

# Asegurar que el proceso se ejecute con el nombre deseado (opcional)
# Usamos 'exec -a' solo si el sistema lo soporta, pero no es crítico.
# En lugar de eso, renombramos el proceso hijo con 'prctl' o 'exec -a' dentro del subshell.
# Para máxima compatibilidad, dejamos el nombre real (bash) pero el PID es el que controlamos.
# Si quieres forzar el nombre, puedes ejecutar: exec -a "$PROCESS_NAME" bash -c 'while true; do sleep 10; done'

# Entonces, mejor aún, lanzamos con exec -a para que se vea bonito:
# Matamos el proceso recién creado y lo recreamos con el nombre adecuado.
kill -9 $new_pid 2>/dev/null
( exec -a "$PROCESS_NAME" bash -c 'while true; do sleep 10; done' ) &
real_pid=$!
echo "$real_pid" > "$PID_FILE"

echo "Proceso '$PROCESS_NAME' iniciado con PID $real_pid."