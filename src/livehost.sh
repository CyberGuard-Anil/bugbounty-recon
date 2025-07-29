#!/bin/bash
# Usage: livehost.sh output_dir

set -euo pipefail

outdir=$1
subdomains_file="$outdir/subdomains.txt"
live_file="$outdir/live.txt"

if [[ ! -s "$subdomains_file" ]]; then
    echo "No subdomains to check live hosts in $subdomains_file"
    exit 1
fi

echo "[*] Running httpx to detect live hosts..."

if ! command -v httpx >/dev/null 2>&1; then
    echo "Error: httpx not found. Please run tools-setup.sh"
    exit 1
fi

httpx -l "$subdomains_file" -silent -o "$live_file"

echo "[*] Live host detection done: $(wc -l < "$live_file") live hosts found."

