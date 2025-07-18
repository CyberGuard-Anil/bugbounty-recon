#!/bin/bash

# ----------------------------------------
# Bug Bounty Recon Framework (Automated)
# Author: Cyber Gaurd x Anil Yadav
# Description: One-click recon tool
# ----------------------------------------

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'
export PATH=$PATH:$HOME/go/bin


# Tool Checker Function
check_tool() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED} Tool '$1' not found. Please run ./tools-setup.sh first.${NC}"
    exit 1
  fi
}

# Check required tools
for tool in subfinder httpx naabu ffuf; do
  check_tool "$tool"
done

# Input domain check
if [ -z "$1" ]; then
  echo -e "${RED} Usage: ./recon.sh <target.com>${NC}"
  exit 1
fi

TARGET=$1
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="./output/$TARGET-$DATE"
WORDLIST="/usr/share/seclists/Discovery/Web-Content/raft-small-words.txt"

mkdir -p "$OUTPUT_DIR/fuzzing"

echo -e "${CYAN} Starting recon for $TARGET...${NC}"
sleep 1

# 1️⃣ Subdomain Enumeration
echo -e "${YELLOW}Finding subdomains (subfinder)...${NC}"
subfinder -d "$TARGET" -silent > "$OUTPUT_DIR/subdomains.txt"

# 2️⃣ Live Host Probing
echo -e "${YELLOW}Probing live hosts (httpx)...${NC}"
httpx -silent -l "$OUTPUT_DIR/subdomains.txt" > "$OUTPUT_DIR/live.txt"

# 3️⃣ Port Scanning
echo -e "${YELLOW}Scanning open ports (naabu)...${NC}"
naabu -l "$OUTPUT_DIR/live.txt" -silent > "$OUTPUT_DIR/ports.txt"

# 4️⃣ Directory Fuzzing (First 3 Live URLs)
echo -e "${YELLOW}Fuzzing directories (ffuf)...${NC}"
count=0
while read url; do
  if [[ $count -ge 3 ]]; then break; fi
  filename=$(echo "$url" | sed 's|https\?://||;s|/||g')
  ffuf -w "$WORDLIST" -u "$url/FUZZ" -of json -o "$OUTPUT_DIR/fuzzing/${filename}.json" -t 30
  ((count++))
done < "$OUTPUT_DIR/live.txt"

echo -e "\n${GREEN}Recon completed successfully!${NC}"
echo -e "${CYAN} Output saved to: $OUTPUT_DIR${NC}"

