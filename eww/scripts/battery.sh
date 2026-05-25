#!/bin/bash

battery_percent=$(cat /sys/class/power_supply/BAT0/capacity)

status=$(cat /sys/class/power_supply/BAT0/status)

echo "(box :class \"bat-bar\" (circular-progress :value ${battery_percent} :hexpand false (eventbox :class \"bat-icon\" :tooltip \"Battery : ${battery_percent}%\" :wrap false \"🔋\")))"
