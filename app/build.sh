#!/bin/bash
# Gradi Pitchi.app bez Xcode-a (Command Line Tools + statički whisper.cpp).
set -euo pipefail
cd "$(dirname "$0")"

CERT="${PITCHI_CERT:-Pichi Local Dev}"
APP="build/Pitchi.app"
BIN="$APP/Contents/MacOS/Pitchi"

if [ ! -f vendor/whisper/lib/libwhisper.a ]; then
  echo "Nedostaje whisper.cpp — pripremam ga (jednokratno, traje par minuta)…"
  bash pripremi-whisper.sh
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

FILES=($(find src -name '*.swift' | sort))

echo "Kompajliram ${#FILES[@]} Swift fajlova…"
swiftc -O -swift-version 5 -parse-as-library \
  -target arm64-apple-macos13.0 \
  -I vendor/whisper/include \
  -import-objc-header src/Pitchi-Bridging-Header.h \
  -o "$BIN" \
  "${FILES[@]}" \
  -Xlinker -force_load -Xlinker vendor/whisper/lib/libggml-metal.a \
  -Xlinker -force_load -Xlinker vendor/whisper/lib/libggml-cpu.a \
  -Xlinker -force_load -Xlinker vendor/whisper/lib/libggml-blas.a \
  vendor/whisper/lib/libwhisper.a \
  vendor/whisper/lib/libggml.a \
  vendor/whisper/lib/libggml-base.a \
  -lc++ \
  -framework AppKit \
  -framework SwiftUI \
  -framework AVFoundation \
  -framework ApplicationServices \
  -framework Security \
  -framework ServiceManagement \
  -framework Metal \
  -framework MetalKit \
  -framework Accelerate \
  -framework Foundation

cp Info.plist "$APP/Contents/Info.plist"
[ -f Resursi/AppIcon.icns ] && cp Resursi/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

if codesign --force --sign "$CERT" "$APP" 2>/dev/null; then
  echo "potpis: $CERT"
else
  codesign --force --sign - "$APP"
  echo "potpis: ad-hoc (dozvole će se tražiti ponovo posle svakog builda)"
fi

echo
echo "napravljeno: $(pwd)/$APP"
echo "pokreni:     open \"$(pwd)/$APP\""
