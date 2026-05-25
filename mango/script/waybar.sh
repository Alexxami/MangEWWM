#/bin/bash
pkill waybar
sleep 1
waybar -s ~/.config/waybar/style-light.css -c ~/.config/waybar/config-light.jsonc
