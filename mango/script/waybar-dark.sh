#/bin/bash
pkill waybar
sleep 1
waybar -s ~/.config/waybar/style-dark.css -c ~/.config/waybar/config-dark.jsonc
