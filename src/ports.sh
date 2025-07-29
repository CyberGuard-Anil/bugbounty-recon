#!/bin/bash
# Usage: ports.sh output_dir

set -euo pipefail

outdir=$1
live_file="$outdir/live.txt"
ports_file="$outdir/ports.txt"

if [[ ! -s "$live_file" ]]; then
    echo "No live hosts to scan ports on in $live_file"
    exit 1
fi

echo "[*] Running naabu for port scanning..."

if ! command -v naabu >/dev/null 2>&1; then
    echo "Error: naabu not found. Please run tools-setup.sh"
    exit 1
fi

# Scan top 1000 ports by default
naabu -iL "$live_file" -top-ports 1000 -silent -o "$ports_file"

echo "[*] Port scanning done."

