#!/bin/bash
# Fake GFortran for Ultra Mode
if [[ "$*" == *"--version"* ]]; then
    echo "GNU Fortran (Ultra Chaos) 13.3.0"
    exit 0
fi
if [[ "$*" == *"-v"* ]]; then
    echo "gcc version 13.3.0 (Ultra Chaos)"
    exit 0
fi
echo "[ULTRA] Fake GFortran called with: $*"
echo "[ULTRA] Pretending to compile Fortran... Done."
touch a.out 2>/dev/null || true
exit 0
