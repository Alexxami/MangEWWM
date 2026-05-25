#!/bin/bash

FILE=".config/mango/script/save_a.json"

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

# Ejecutar el comando correspondiente según el NUEVO valor
if [[ "$NEW" -eq 0 ]]; then
    mmsg -d setlayout,dwindle
else
    mmsg -d setlayout,vertical_scroller
fi
