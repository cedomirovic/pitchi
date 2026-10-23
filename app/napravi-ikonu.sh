#!/bin/bash
# Pravi AppIcon.icns iz AppIcon-1024.png (bez dodatnih alata osim sips/iconutil).
set -euo pipefail
cd "$(dirname "$0")"

swift napravi-ikonu.swift

ICONSET="Resursi/Diktator.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

for velicina in 16 32 128 256 512; do
  sips -z "$velicina" "$velicina" Resursi/AppIcon-1024.png --out "$ICONSET/icon_${velicina}x${velicina}.png" >/dev/null
  dupla=$((velicina * 2))
  sips -z "$dupla" "$dupla" Resursi/AppIcon-1024.png --out "$ICONSET/icon_${velicina}x${velicina}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o Resursi/AppIcon.icns
rm -rf "$ICONSET"
echo "napravljeno: Resursi/AppIcon.icns"
