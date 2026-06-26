#!/bin/bash
# Devuelve el porcentaje de brillo (0-100)
brightness=$(brightnessctl get)
max=$(brightnessctl max)
percent=$((brightness * 100 / max))
echo "$percent"
