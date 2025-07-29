#!/bin/bash
# Usage: subdomain.sh domain output_dir

set -euo pipefail

domain=$1
outdir=$2

output_file="$outdir/subdomains.txt"
echo "[*] Running subfinder for $domain..."

if ! command -v subfinder >/dev/null 2>&1; then
    echo "Error: subfinder command not found, please run tools-setup.sh"
    exit 1
fi

subfinder -d "$domain" -silent -o "$output_file"

echo "[*] Subdomain enumeration done: $(wc -l < "$output_file") subdomains found."

