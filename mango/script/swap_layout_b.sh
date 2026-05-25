#!/bin/bash

FILE=".config/mango/script/save_b.json"

# Si no existe, crearlo con valor 0
if [[ ! -f "$FILE" ]]; then
    echo '{"value": 0}' > "$FILE"
fi

# Leer valor actual con jq
CURRENT=$(jq '.value' "$FILE")

# Alternar valor
NEW=$((1 - CURRENT))

# Escribir nuevo valor en el JSON (de forma atómica)
jq --argjson new "$NEW" '.value = $new' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

echo "Valor cambiado de $CURRENT a $NEW"

# Ejecutar el comando correspondiente según el NUEVO valor
if [[ "$NEW" -eq 0 ]]; then
    echo "Ejecutando layout: vertical_grid"
    mmsg -d setlayout,vertical_grid
else
    echo "Ejecutando layout: scroller"
    mmsg -d setlayout,scroller
fi
