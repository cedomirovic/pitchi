#!/bin/bash
# Gradi i instalira Pitchi u /Applications. Postojeću verziju čuva kao .bak.
set -euo pipefail
cd "$(dirname "$0")"

CILJ="/Applications/Pitchi.app"
CERT="${PITCHI_CERT:-Pichi Local Dev}"

bash build.sh

if [ -e "$CILJ" ]; then
  if [ "${1:-}" != "--prepisi" ]; then
    echo
    echo "Već postoji $CILJ."
    echo "Pokreni ponovo sa --prepisi da ga zameniš (stara verzija ide u Pitchi.app.bak)."
    exit 1
  fi
  osascript -e 'tell application "Pitchi" to quit' >/dev/null 2>&1 || true
  sleep 1
  rm -rf "$CILJ.bak"
  mv "$CILJ" "$CILJ.bak"
  echo "stara verzija: $CILJ.bak"
fi

ditto build/Pitchi.app "$CILJ"

if codesign --force --sign "$CERT" "$CILJ" 2>/dev/null; then
  echo "potpis: $CERT"
else
  codesign --force --sign - "$CILJ"
  echo "potpis: ad-hoc"
fi

echo "instalirano: $CILJ"
open "$CILJ"
