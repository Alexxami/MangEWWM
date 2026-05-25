#!/bin/bash
# Obtiene el historial de dunst y lo convierte a un box de EWW

history=$(dunstctl history 2>/dev/null)
if [ -z "$history" ]; then
    echo "(box :orientation 'vertical')"
    exit 0
fi

# Extraer notificaciones con jq
notifications=$(echo "$history" | jq -c '.data[].notification')

output="(box :orientation 'vertical' :spacing 8"
while IFS= read -r notif; do
    summary=$(echo "$notif" | jq -r '.summary // ""')
    body=$(echo "$notif" | jq -r '.body // ""')
    app=$(echo "$notif" | jq -r '.appname // ""')
    icon=$(echo "$notif" | jq -r '.icon // ""')
    
    # Escapar comillas simples para no romper la sintaxis de EWW
    summary=${summary//\'/\\\'}
    body=${body//\'/\\\'}
    app=${app//\'/\\\'}
    icon=${icon//\'/\\\'}
    
    output+=" (button :class 'notif' :onclick 'dunstctl close' (box :orientation 'h' :spacing 10 (image :image-width 40 :image-height 40 :path '$icon') (box :orientation 'v' :space-evenly false (label :text '$summary' :wrap true) (label :text '$body' :wrap true))))"
done <<< "$notifications"

output+=")"
echo "$output"
