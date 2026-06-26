#!/bin/bash
base_dir="$HOME/.config/eww/"
image_file="${base_dir}image.jpg"
mkdir -p "$base_dir"

download_image() {
    local url="$1"
    local tmp="${image_file}.tmp"
    if wget -q --timeout=3 --tries=1 -O "$tmp" "$url"; then
        mv "$tmp" "$image_file"
        return 0
    else
        rm -f "$tmp"
        return 1
    fi
}

fetch_cover_from_itunes() {
    local artist="$1"
    local title="$2"
    local query=$(printf '%s %s' "$artist" "$title" | sed 's/ /+/g;s/[&?]//g')
    local api_url="https://itunes.apple.com/search?term=${query}&limit=1&entity=song"
    local art_url=$(curl -s "$api_url" | jq -r '.results[0].artworkUrl100 // empty')
    if [[ -n "$art_url" ]]; then
        art_url="${art_url//100x100/600x600}"
        download_image "$art_url" && return 0
    fi
    return 1
}

# Usamos un formato que incluya todos los campos posibles de duración
playerctl metadata -F -f '{{playerName}}|{{title}}|{{artist}}|{{mpris:artUrl}}|{{xesam:length}}|{{mpris:length}}|{{duration}}|{{status}}' | \
while IFS='|' read -r name title artist artUrl xesamLength mprisLength durationRaw status; do

    # ----- Duración total (en segundos) -----
    len_sec=""
    # Prioridad: duration (segundos) > xesamLength (microsegundos) > mprisLength (microsegundos)
    if [[ -n "$durationRaw" && "$durationRaw" =~ ^[0-9]+$ ]]; then
        len_sec="$durationRaw"
    elif [[ -n "$xesamLength" && "$xesamLength" =~ ^[0-9]+$ ]]; then
        len_sec=$(( xesamLength / 1000000 ))
    elif [[ -n "$mprisLength" && "$mprisLength" =~ ^[0-9]+$ ]]; then
        len_sec=$(( mprisLength / 1000000 ))
    fi

    # Formatear mm:ss
    if [[ -n "$len_sec" ]]; then
        mins=$(( len_sec / 60 ))
        secs=$(( len_sec % 60 ))
        lengthStr=$(printf "%d:%02d" "$mins" "$secs")
    else
        lengthStr=""
    fi

    # ----- Carátula (igual que antes) -----
    success=false
    if [[ -n "$artUrl" && "$artUrl" != "null" ]]; then
        if [[ "$artUrl" =~ ^https?:// ]]; then
            download_image "$artUrl" && success=true
        elif [[ "$artUrl" =~ ^file:// ]]; then
            local_path="${artUrl#file://}"
            if [[ -f "$local_path" ]]; then
                cp "$local_path" "$image_file" && success=true
            fi
        elif [[ -f "$artUrl" ]]; then
            cp "$artUrl" "$image_file" && success=true
        fi
    fi

    if [[ "$success" != "true" ]]; then
        if [[ -n "$artist" && -n "$title" ]]; then
            fetch_cover_from_itunes "$artist" "$title" && success=true
        fi
    fi

    if [[ "$success" != "true" ]]; then
        cp "${base_dir}scripts/cover.png" "$image_file" 2>/dev/null || true
    fi

    # ----- JSON de salida -----
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