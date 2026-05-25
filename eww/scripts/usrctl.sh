#!/bin/bash

if [[ -z $(eww active-windows | grep 'usrctl') ]]; then
    /usr/bin/eww open usrctl && /usr/bin/eww update ctlrev=true
else
    /usr/bin/eww update ctlrev=false
    (sleep 0.2 && /usr/bin/eww close usrctl) &
fi
