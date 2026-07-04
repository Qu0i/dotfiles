#!/bin/bash

if command -v asusctl &> /dev/null; then
    asusctl profile next
    CURRENT=$(asusctl profile get | grep 'Active profile:' | awk '{print $NF}')
    case "$CURRENT" in
        "Performance")
            DESC="Set to Performance (High Speed)"
            ;;
        "Quiet")
            DESC="Set to Quiet (Silent Speed)"
            ;;
        *)
            DESC="Set to Balanced (Normal Speed)"
            ;;
    esac
    notify-send -u normal -t 3000 -i fan-symbolic "Fan Control" "$DESC"
else
    CURRENT=$(powerprofilesctl get)
    case "$CURRENT" in
        "power-saver")
            powerprofilesctl set balanced
            notify-send -u normal -t 3000 -i fan-symbolic "Fan Control" "Set to Balanced (Normal Speed)"
            ;;
        "balanced")
            powerprofilesctl set performance
            notify-send -u normal -t 3000 -i fan-symbolic "Fan Control" "Set to Performance (High Speed)"
            ;;
        *)
            powerprofilesctl set power-saver
            notify-send -u normal -t 3000 -i fan-symbolic "Fan Control" "Set to Power Saver (Quiet Speed)"
            ;;
    esac
fi

# Update waybar modules
pkill -RTMIN+8 waybar   # Battery custom module
pkill -RTMIN+9 waybar   # Temperature custom module
pkill -RTMIN+10 waybar  # Fan custom module
