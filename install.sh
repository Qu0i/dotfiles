#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "[*] Installing dotfiles..."

mkdir -p "$CONFIG_DIR"

for dir in "$SCRIPT_DIR"/*; do
    [[ -d "$dir" ]] || continue

    name="$(basename "$dir")"

    echo "[+] Installing $dir"
    cp -r "$dir" "$CONFIG_DIR/"
done

echo "[✓] Installation complete!"
