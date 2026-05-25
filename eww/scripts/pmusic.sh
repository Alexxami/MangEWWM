#!/bin/bash

playerctl metadata -F -f '{{playerName}}|{{position}}|{{mpris:length}}' | while IFS='|' read -r player position length; do
    pos_sec=$(( (position + 500000) / 1000000 ))
    len_sec=$(( (length + 500000) / 1000000 ))
    mins=$((pos_sec / 60))
    secs=$((pos_sec % 60))
    pos_str=$(printf "%d:%02d" "$mins" "$secs")
    jq -n -c \
      --arg position "$pos_sec" \
      --arg positionStr "$pos_str" \
      '{position: $position, positionStr: $positionStr}'
done
