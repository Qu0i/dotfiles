#!/bin/bash

# Меню выключения с использованием wofi
CHOICE=$(echo -e "🔴 Выключить\n🔃 Перезагрузить\n🚪 Выйти\n💤 Сон\n🔒 Блокировка" | wofi --dmenu --prompt "" --width 960 --height 50)

case "$CHOICE" in
    "🔴 Выключить")
        systemctl poweroff
        ;;
    "🔃 Перезагрузить")
        systemctl reboot
        ;;
    "🚪 Выйти")
        hyprctl dispatch exit
        ;;
    "💤 Сон")
        systemctl suspend
        ;;
    "🔒 Блокировка")
        loginctl lock-session
        ;;
    *)
        exit 0
        ;;
esac
