#!/usr/bin/env bash
CACHE_DIR="/tmp/eww-album-art"
mkdir -p "$CACHE_DIR"
ART_URL=$(playerctl metadata mpris:artUrl 2>/dev/null)
if [ -z "$ART_URL" ]; then
    echo "$HOME/.config/eww/assets/default-album.png"
    exit 0
fi
HASH=$(echo -n "$ART_URL" | md5sum | cut -d' ' -f1)
IMAGE_PATH="$CACHE_DIR/$HASH.jpg"
if [ -f "$IMAGE_PATH" ]; then
    echo "$IMAGE_PATH"
else
    curl -s -o "$IMAGE_PATH" "$ART_URL"
    echo "$IMAGE_PATH"
fi