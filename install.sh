#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "[*] Installing dotfiles..."

mkdir -p "$CONFIG_DIR"

for dir in hypr kitty waybar zsh; do
    echo "[+] Installing $dir"
    cp -r "$SCRIPT_DIR/$dir" "$CONFIG_DIR/"
done

echo "[✓] Installation complete!"
