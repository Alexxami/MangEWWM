#!/bin/bash
base_dir="$HOME/.config/eww/"
image_file="${base_dir}image.jpg"

mkdir -p "$base_dir"

playerctl metadata -F -f '{{playerName}}|{{title}}|{{artist}}|{{mpris:artUrl}}|{{status}}|{{mpris:length}}' | while IFS='|' read -r name title artist artUrl status length; do
    if [[ -n "$length" && "$length" =~ ^[0-9]+$ ]]; then
        len_sec=$(( (length + 500000) / 1000000 ))
        mins=$((len_sec / 60))
        secs=$((len_sec % 60))
        lengthStr=$(printf "%d:%02d" "$mins" "$secs")
    else
        len_sec=""
        lengthStr=""
    fi
    if [[ "$artUrl" =~ ^https?:// ]]; then
        tmp_image="${image_file}.tmp"
        if wget -q -O "$tmp_image" "$artUrl"; then
            mv "$tmp_image" "$image_file"
        else
            rm -f "$image_file"
            cp "${base_dir}scripts/cover.png" "$image_file"
        fi
    else
        cp "${base_dir}scripts/cover.png" "$image_file"
    fi
    jq -n -c \
        --arg name "$name" \
        --arg title "$title" \
        --arg artist "$artist" \
        --arg artUrl "$image_file" \
        --arg status "$status" \
        --arg length "$len_sec" \
        --arg lengthStr "$lengthStr" \
        '{name: $name, title: $title, artist: $artist, thumbnail: $artUrl, status: $status, length: $length, lengthStr: $lengthStr}'
done
