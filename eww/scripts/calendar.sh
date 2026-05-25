#!/bin/bash

if [[ -z $(eww active-windows | grep 'calendar') ]]; then
    /usr/bin/eww open calendar && /usr/bin/eww update calrev=true
else
    /usr/bin/eww update calrev=false
    (sleep 0.2 && /usr/bin/eww close calendar) &
fi
