#!/bin/bash
# Usage: fuzz.sh output_dir

set -euo pipefail

outdir=$1
live_file="$outdir/live.txt"
fuzz_dir="$outdir/fuzzing"
wordlist_path="/usr/share/seclists/Discovery/Web-Content/common.txt"

if [[ ! -s "$live_file" ]]; then
    echo "No live hosts to fuzz in $live_file"
    exit 1
fi

if [[ ! -f "$wordlist_path" ]]; then
    echo "Wordlist missing at $wordlist_path. Please install seclists (sudo apt install seclists) or update path."
    exit 1
fi

if ! command -v ffuf >/dev/null 2>&1; then
    echo "Error: ffuf not found. Please run tools-setup.sh"
    exit 1
fi

echo "[*] Starting directory fuzzing on live hosts..."

i=1
while read -r host; do
    outjson="$fuzz_dir/live${i}.json"
    ffuf -u "https://$host/FUZZ" -w "$wordlist_path" -ac 200,204,301,302,307,401,403 -o "$outjson" -of json -silent &
    ((i++))
done < "$live_file"

wait

echo "[*] Directory fuzzing completed."

