#!/usr/bin/env bash
# scripts/dunst_history.sh

# Obtener el historial de dunst en JSON
history=$(dunstctl history 2>/dev/null)

# Si está vacío o hay error, mostrar un array vacío
if [[ -z "$history" ]]; then
    echo '[]'
    exit 0
fi

# Extraer solo los campos necesarios: appname, summary, body, urgency, id
echo "$history" | jq -c '[ .data[].notification | {
    id: .id,
    appname: .appname,
    summary: .summary.data,
    body: (.body.data // ""),
    urgency: .urgency
} ]'
