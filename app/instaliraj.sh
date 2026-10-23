#!/bin/bash
# Gradi i instalira Diktator u /Applications. Postojeću verziju čuva kao .bak.
set -euo pipefail
cd "$(dirname "$0")"

CILJ="/Applications/Diktator.app"
CERT="${DIKTATOR_CERT:-Pichi Local Dev}"

# Stara aplikacija ima isti bundle identifikator, pa ne sme da ostane u
# /Applications pored nove — macOS bi mogao da pokrene pogrešnu kopiju.
STARI_ID="com.cedomirovic.pitchi"

bash build.sh

if [ -e "$CILJ" ] && [ "${1:-}" != "--prepisi" ]; then
  echo
  echo "Već postoji $CILJ."
  echo "Pokreni ponovo sa --prepisi da ga zameniš (stara verzija ide u Diktator.app.bak)."
  exit 1
fi

# Nađi stariju kopiju po bundle identifikatoru, bez obzira na ime fajla.
for KANDIDAT in /Applications/*.app; do
  [ -e "$KANDIDAT" ] || continue
  [ "$KANDIDAT" = "$CILJ" ] && continue
  ID="$(plutil -extract CFBundleIdentifier raw -o - "$KANDIDAT/Contents/Info.plist" 2>/dev/null || true)"
  if [ "$ID" = "$STARI_ID" ]; then
    osascript -e "tell application id \"$STARI_ID\" to quit" >/dev/null 2>&1 || true
    sleep 1
    rm -rf "$KANDIDAT.bak"
    mv "$KANDIDAT" "$KANDIDAT.bak"
    echo "stara aplikacija: $KANDIDAT.bak"
  fi
done

if [ -e "$CILJ" ]; then
  osascript -e 'tell application "Diktator" to quit' >/dev/null 2>&1 || true
  sleep 1
  rm -rf "$CILJ.bak"
  mv "$CILJ" "$CILJ.bak"
  echo "stara verzija: $CILJ.bak"
fi

ditto build/Diktator.app "$CILJ"

if codesign --force --sign "$CERT" "$CILJ" 2>/dev/null; then
  echo "potpis: $CERT"
else
  codesign --force --sign - "$CILJ"
  echo "potpis: ad-hoc"
fi

echo "instalirano: $CILJ"
open "$CILJ"
