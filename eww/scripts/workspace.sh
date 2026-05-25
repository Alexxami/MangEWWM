#!/bin/bash

# Número máximo de workspaces (tags) que quieres mostrar
MAX_TAGS=6

# Función que construye la cadena del widget de workspaces
build_workspaces() {
    local output=""
    local current_tag=1
    local occupied_tags=""

    # Obtener la salida de mmsg -g -t
    local tag_info=$(mmsg -g -t)

    # Parsear línea por línea para obtener tag actual y ocupados
    while IFS= read -r line; do
        # Formato esperado: "DP-3 tag N A B C" donde A=focused, B=clients
        if [[ $line =~ tag\ ([0-9]+)\ ([0-9]+)\ ([0-9]+) ]]; then
            tag=${BASH_REMATCH[1]}
            focused=${BASH_REMATCH[2]}   # 1 si es el tag activo
            clients=${BASH_REMATCH[3]}   # número de ventanas en el tag
            if (( focused == 1 )); then
                current_tag=$tag
            fi
            if (( clients > 0 )); then
                occupied_tags="$occupied_tags $tag"
            fi
        fi
    done <<< "$tag_info"

    # Construir la cadena del widget
    output="(box :class \"ws\" :halign \"end\" :orientation \"h\" :spacing 5 :space-evenly \"false\""
    for ((i=1; i<=MAX_TAGS; i++)); do
        if (( i == current_tag )); then
            class="visiting"
            icon=" "   # círculo relleno (activo)
        elif [[ "$occupied_tags" =~ (^|[[:space:]])$i($|[[:space:]]) ]]; then
            class="occupied"
            icon=" "   # o " " si prefieres otro icono
        else
            class="free"
            icon=" "   # círculo vacío
        fi
        output+=" (eventbox :onclick \"mmsg -t $i\" :cursor \"pointer\" :class \"$class\" (label :text \"$icon\"))"
    done
    output+=")"
    echo "$output"
}

# Inicializar variable con un valor por defecto
/usr/bin/eww update workspaces-output="$(build_workspaces)"

# Bucle de polling (comprueba cada 0.5 segundos)
while true; do
    sleep 0.5
    new_output=$(build_workspaces)
    current_output=$(/usr/bin/eww get workspaces-output 2>/dev/null)
    if [[ "$new_output" != "$current_output" ]]; then
        /usr/bin/eww update workspaces-output="$new_output"
    fi
done