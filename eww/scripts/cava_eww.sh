#!/usr/bin/env bash

# Crear un archivo temporal para la configuración de cava
CONFIG=$(mktemp)

cat > "$CONFIG" <<EOF
[general]
bars = 20
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 40
bar_delimiter = 32
EOF

# Ejecutar cava con la configuración temporal
cava -p "$CONFIG"

# Borrar el archivo al salir (nunca se llega porque cava corre hasta matarlo)
rm -f "$CONFIG"
