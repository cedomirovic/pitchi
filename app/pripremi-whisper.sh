#!/bin/bash
# Jednokratna priprema whisper.cpp: klonira, gradi statičke biblioteke sa Metalom
# i kopira ih u vendor/whisper (koji se ne commituje).
set -euo pipefail
cd "$(dirname "$0")"

VER="${WHISPER_VER:-v1.9.5}"
SRC="${WHISPER_SRC:-/tmp/whisper-cpp-$VER}"

if ! command -v cmake >/dev/null 2>&1; then
  echo "Nedostaje cmake. Instaliraj ga sa: brew install cmake" >&2
  exit 1
fi

if [ ! -d "$SRC/.git" ]; then
  git clone --depth 1 --branch "$VER" https://github.com/ggml-org/whisper.cpp "$SRC"
fi

cmake -S "$SRC" -B "$SRC/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DWHISPER_BUILD_EXAMPLES=OFF \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_BUILD_SERVER=OFF \
  -DGGML_METAL=ON \
  -DGGML_METAL_EMBED_LIBRARY=ON \
  -DGGML_BLAS=ON \
  -DGGML_BLAS_VENDOR=Apple \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0

cmake --build "$SRC/build" -j"$(sysctl -n hw.ncpu)"

mkdir -p vendor/whisper/lib vendor/whisper/include
cp "$SRC"/include/*.h vendor/whisper/include/
cp "$SRC"/ggml/include/*.h vendor/whisper/include/
cp "$SRC/build/src/libwhisper.a" vendor/whisper/lib/
cp "$SRC"/build/ggml/src/*.a vendor/whisper/lib/ 2>/dev/null || true
cp "$SRC/build/ggml/src/ggml-metal/libggml-metal.a" vendor/whisper/lib/
cp "$SRC/build/ggml/src/ggml-blas/libggml-blas.a" vendor/whisper/lib/

echo "whisper.cpp je spreman u app/vendor/whisper."
