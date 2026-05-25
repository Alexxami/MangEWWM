#!/bin/bash

DEST="$HOME/Imágenes/Capturas"
mkdir -p "$DEST"
FILE="$DEST/Captura-$(date +%F-%H%M%S).png"

if [ "$1" = "--full" ] || [ "$1" = "-f" ]; then
    # Captura de pantalla completa
    grim - | tee "$FILE" | wl-copy
else
    # Captura de área seleccionada
    grim -g "$(slurp)" - | tee "$FILE" | wl-copy
fi

notify-send -a "Captura" -u low -i "$FILE" "Screenshooted" "See it in $FILE"