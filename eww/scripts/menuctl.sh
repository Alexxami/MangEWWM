#!/bin/bash

if [[ -z $(eww active-windows | grep 'menuctl') ]]; then
    /usr/bin/eww open menuctl && /usr/bin/eww update menurev=true
else
    /usr/bin/eww update menurev=false
    (sleep 0.2 && /usr/bin/eww close menuctl) &
fi
