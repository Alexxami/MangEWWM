#!/usr/bin/env bash
set -eo pipefail

# Plik do śledzenia czasu ostatniej aktywności
TIMESTAMP_FILE="/tmp/eww_spotify_timestamp"
COVER="/tmp/eww_cover.jpg"
DEFAULT_ICON="/usr/share/icons/Adwaita/scalable/mimetypes/audio-x-generic.svg"

# Sprawdź status playera
STATUS=$(playerctl --player=spotify status 2>/dev/null || echo "Stopped")

if [ "$STATUS" = "Playing" ]; then
    # Zapisz aktualny czas jako "ostatnio widziany playing"
    date +%s > "$TIMESTAMP_FILE"
    IS_VISIBLE="true"
else
    # Sprawdź ile minęło od ostatniego grania
    NOW=$(date +%s)
    LAST=$(cat "$TIMESTAMP_FILE" 2>/dev/null || echo "$NOW")
    DIFF=$((NOW - LAST))
    
    # Jeśli minęło więcej niż 10s -> ukryj
    if [ "$DIFF" -gt 10 ]; then
        IS_VISIBLE="false"
    else
        IS_VISIBLE="true"
    fi
fi

# Jeśli ma być ukryty, zwracamy pusty JSON z flagą visible="false"
if [ "$IS_VISIBLE" = "false" ]; then
  echo "{\"visible\": \"false\"}"
  exit 0
fi

# --- Pobieranie danych ---
title=$(playerctl --player=spotify metadata title 2>/dev/null | tr -d '"')
artist=$(playerctl --player=spotify metadata artist 2>/dev/null | tr -d '"')
album=$(playerctl --player=spotify metadata album 2>/dev/null | tr -d '"' )  # Zachowane dla przyszłości
arturl=$(playerctl --player=spotify metadata mpris:artUrl 2>/dev/null || echo "")
arturl="${arturl/https:\/\/open.spotify.com\/image\//https:\/\/i.scdn.co\/image\/}"

# Pobierz pozycję w sekundach (playerctl position zwraca sekundy jako float)
position=$(playerctl --player=spotify position 2>/dev/null || echo "0")
# Pobierz długość w mikrosekundach
length=$(playerctl --player=spotify metadata mpris:length 2>/dev/null || echo "0")
dur_sec=$((length / 1000000))

# Oblicz fraction (0.0 - 1.0)
if [ "$dur_sec" -gt 0 ]; then
    fraction=$(LC_NUMERIC=C awk "BEGIN { printf \"%.4f\", $position / $dur_sec }")
else
    fraction="0"
fi

# Konwersja pozycji na integer sekundy
pos_sec=$(LC_NUMERIC=C printf "%.0f" "$position")

if [[ "$arturl" == http* ]]; then
  curl -s -L -A "Mozilla/5.0" "$arturl" -o "$COVER" &
  [ -s "$COVER" ] && IMG_PATH="$COVER" || IMG_PATH="$DEFAULT_ICON"
elif [[ "$arturl" == file://* ]]; then
  IMG_PATH="${arturl#file://}"
else
  IMG_PATH="$DEFAULT_ICON"
fi

jq -n \
  --arg visible "$IS_VISIBLE" \
  --arg title "$title" \
  --arg artist "$artist" \
  --arg status "$STATUS" \
  --arg cover "$IMG_PATH" \
  --arg fraction "$fraction" \
  --argjson pos_sec "$pos_sec" \
  --argjson dur_sec "$dur_sec" \
  '{visible: $visible, title:$title, artist:$artist, status:$status, cover:$cover, fraction:$fraction, pos_sec:$pos_sec, dur_sec:$dur_sec}'

