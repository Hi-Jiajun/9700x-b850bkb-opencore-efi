#!/bin/bash
# Sanity-check this public checkout: placeholders intact, no binaries, valid plist.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT/EFI/OC/config.plist"
status=0

if [ ! -f "$CONFIG" ]; then
  echo "FAIL: $CONFIG missing"
  exit 1
fi

if ! plutil -lint "$CONFIG" >/dev/null; then
  echo "FAIL: config.plist is not a valid plist"
  status=1
fi

for pair in \
  "SystemSerialNumber:XXXXXXXXXXXX" \
  "MLB:XXXXXXXXXXXXXXXXX" \
  "SystemUUID:00000000-0000-0000-0000-000000000000"; do
  key=${pair%%:*}
  want=${pair#*:}
  got=$(/usr/libexec/PlistBuddy -c "Print :PlatformInfo:Generic:$key" "$CONFIG" 2>/dev/null || true)
  if [ "$got" != "$want" ]; then
    echo "FAIL: $key = '$got', expected placeholder '$want'"
    status=1
  fi
done

if find "$ROOT" -path "$ROOT/.git" -prune -o \
     \( -name "*.kext" -o -name "*.efi" \) -print | grep -q .; then
  echo "FAIL: binary kext/driver found in a text-only repo"
  find "$ROOT" -path "$ROOT/.git" -prune -o \
     \( -name "*.kext" -o -name "*.efi" \) -print
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "ok: placeholders intact, no binaries, plist valid"
fi
exit "$status"
