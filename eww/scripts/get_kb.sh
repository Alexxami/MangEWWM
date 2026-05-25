#!/bin/bash

HYPRLAND_SIGNATURE_ACTUAL=$(ls -td /run/user/1000/hypr/*/ 2>/dev/null | head -n1 | xargs basename)

socat -u UNIX-CONNECT:/run/user/1000/hypr/"$HYPRLAND_SIGNATURE_ACTUAL"/.socket2.sock - |
    stdbuf -o0 awk -F '>>|,' '/^activelayout>>/ { print toupper(substr($3, 1, 2)) }'
