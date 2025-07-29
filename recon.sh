#!/bin/bash

# ----------------------------------------
# Bug Bounty Recon Framework (Automated)
# Author: Cyber Gaurd x Anil Yadav
# Description: One-click recon tool
# ----------------------------------------

set -euo pipefail

# Colors for output
RED=$(tput setaf 1)
GRN=$(tput setaf 2)
YEL=$(tput setaf 3)
BLU=$(tput setaf 4)
RST=$(tput sgr0)

LOGFILE=""

log() {
    echo -e "[$(date +'%H:%M:%S')] ${GRN}[INFO]${RST} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOGFILE"
}

err() {
    echo -e "[$(date +'%H:%M:%S')] ${RED}[ERROR]${RST} $1" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOGFILE"
}

usage() {
    echo -e "${BLU}Usage:${RST} $0 domain.com"
    echo -e "Example: $0 hackerone.com"
    exit 1
}

trap_cleanup() {
    err "Script interrupted! Cleaning up..."
    # Kill background jobs if any
    jobs -p | xargs -r kill
    exit 130
}
trap trap_cleanup INT

# Check input argument
if [[ $# -ne 1 ]]; then
    usage
fi

domain=$1

# Validate domain with simple regex (basic)
if ! [[ $domain =~ ^([a-zA-Z0-9][-a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$ ]]; then
    err "Invalid domain format: $domain"
    exit 1
fi

# Prepare output folder with timestamp
ts=$(date '+%Y-%m-%d_%H-%M-%S')
outdir="output/${domain}-${ts}"
mkdir -p "$outdir/fuzzing"

LOGFILE="$outdir/recon.log"
touch "$LOGFILE"
log "Starting bug bounty recon for $domain"

# Source modular scripts
script_dir="$(dirname "$(realpath "$0")")/src"
if [[ ! -d $script_dir ]]; then
    err "src/ folder missing! Please ensure modular scripts exist."
    exit 1
fi

# Run subdomain enumeration
bash "$script_dir/subdomain.sh" "$domain" "$outdir"
if [[ $? -ne 0 ]]; then
    err "Subdomain enumeration failed."
    exit 2
fi

# Run live host detection
bash "$script_dir/livehost.sh" "$outdir"
if [[ $? -ne 0 ]]; then
    err "Live host detection failed."
    exit 3
fi

# Run port scanning (background)
bash "$script_dir/ports.sh" "$outdir" & 
pid_ports=$!

# Run directory fuzzing (background)
bash "$script_dir/fuzz.sh" "$outdir" &
pid_fuzz=$!

wait $pid_ports
if [[ $? -ne 0 ]]; then
    err "Port scanning failed."
    exit 4
fi

wait $pid_fuzz
if [[ $? -ne 0 ]]; then
    err "Directory fuzzing failed."
    exit 5
fi

log "Recon completed for $domain."
log "Results saved in $outdir"
echo -e "${GRN}Done!${RST} Check outputs in $outdir"

