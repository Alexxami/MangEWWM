#!/bin/bash

while true; do
    CHARGE_NOW=$(cat /sys/class/power_supply/BAT0/charge_now)
    CURRENT_NOW=$(cat /sys/class/power_supply/BAT0/current_now)
    CURRENT_NOW=${CURRENT_NOW#-}
    CHARGE_FULL=$(cat /sys/class/power_supply/BAT0/charge_full)
    STATUS=$(cat /sys/class/power_supply/BAT0/status)

    if [ "$CURRENT_NOW" -ne 0 ]; then
        if [[ "$STATUS" == "Discharging" ]]; then
            MINUTES_LEFT=$(( CHARGE_NOW * 60 / CURRENT_NOW ))
            HOURS=$(( MINUTES_LEFT / 60 ))
            MINS=$(( MINUTES_LEFT % 60 ))
            echo "$HOURS h $MINS min left, $STATUS"
        elif [[ "$STATUS" == "Charging" ]]; then
            DIFF=$(( CHARGE_FULL - CHARGE_NOW ))
            MINUTES_TO_FULL=$(( DIFF * 60 / CURRENT_NOW ))
            HOURS=$(( MINUTES_TO_FULL / 60 ))
            MINS=$(( MINUTES_TO_FULL % 60 ))
            echo "$HOURS h $MINS min to full, $STATUS"
        else
            echo "0 h 0 min to full, $STATUS"
        fi
    fi
    sleep 1
done
