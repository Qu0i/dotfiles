#!/bin/bash

# Get current power profile
CURRENT=$(powerprofilesctl get)

# Path to battery rofi theme
THEME_PATH="/home/amalskumar/.config/waybar/scripts/battery_rofi.rasi"

show_rofi_alert() {
    local message="$1"
    local duration="$2"
    local cmd=("rofi")
    if [ -f "$THEME_PATH" ]; then
        cmd+=("-theme" "$THEME_PATH")
    fi
    cmd+=("-e" "$message")
    
    # Run in background and kill after duration
    "${cmd[@]}" &
    local pid=$!
    (
        sleep "$duration"
        kill "$pid" 2>/dev/null
    ) &
}

if command -v asusctl &> /dev/null; then
    CURRENT=$(asusctl profile get | grep 'Active profile:' | awk '{print $NF}')
    if [ "$CURRENT" = "Quiet" ]; then
        asusctl profile set Balanced
        pkill -RTMIN+8 waybar
        pkill -RTMIN+9 waybar
        pkill -RTMIN+10 waybar
        notify-send -u normal -t 3000 -i preferences-system-power "Power Profile" "Switched to Balanced Mode"
        show_rofi_alert "󰓅   <span color='#a2d2ff'><b>Balanced Mode Active</b></span>" 2
    else
        asusctl profile set Quiet
        brightnessctl set 0
        pkill -RTMIN+8 waybar
        pkill -RTMIN+9 waybar
        pkill -RTMIN+10 waybar
        notify-send -u normal -t 3000 -i preferences-system-power "Power Profile" "Switched to Power Saver Mode"
        show_rofi_alert "   <span color='#06d6a0'><b>Power Saver Active</b></span>" 2
    fi
else
    if [ "$CURRENT" = "power-saver" ]; then
        powerprofilesctl set balanced
        pkill -RTMIN+8 waybar
        pkill -RTMIN+9 waybar
        pkill -RTMIN+10 waybar
        notify-send -u normal -t 3000 -i preferences-system-power "Power Profile" "Switched to Balanced Mode"
        show_rofi_alert "󰓅   <span color='#a2d2ff'><b>Balanced Mode Active</b></span>" 2
    else
        powerprofilesctl set power-saver
        brightnessctl set 0
        pkill -RTMIN+8 waybar
        pkill -RTMIN+9 waybar
        pkill -RTMIN+10 waybar
        notify-send -u normal -t 3000 -i preferences-system-power "Power Profile" "Switched to Power Saver Mode"
        show_rofi_alert "   <span color='#06d6a0'><b>Power Saver Active</b></span>" 2
    fi
fi

