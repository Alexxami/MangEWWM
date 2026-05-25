#!/bin/bash

/usr/bin/eww update keyhov=true
(sleep 0.45 && /usr/bin/eww update keyrev="$(/usr/bin/eww get keyhov)") &
