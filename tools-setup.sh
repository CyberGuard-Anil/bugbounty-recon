#!/bin/bash

# ----------------------------------------
# Tool Setup Script for Bug Bounty Recon
# Author: Cyber Guard x Anil Yadav
# Version: One-click auto-fix edition 🔥
# ----------------------------------------

echo -e "\n\033[1;36m🚀 Starting tool installation...\033[0m"

# ✅ Step 1: Install Golang if missing
if ! command -v go &>/dev/null; then
  echo -e "\033[1;33m[*] Golang not found. Installing golang...\033[0m"
  sudo apt update
  sudo apt install golang -y
fi

# ✅ Step 2: Setup Go environment variables (if missing)
if [[ ":$PATH:" != *"$HOME/go/bin"* ]]; then
  echo -e "\033[1;33m[*] Adding Go path to ~/.bashrc...\033[0m"
  echo 'export GOPATH=$HOME/go' >> ~/.bashrc
  echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
  export GOPATH=$HOME/go
  export PATH=$PATH:$GOPATH/bin
  source ~/.bashrc
fi

# ✅ Step 3: Install Tools
declare -A tools=(
  ["subfinder"]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  ["httpx"]="go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
  ["naabu"]="go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
  ["ffuf"]="sudo apt install ffuf -y"
)

for tool in "${!tools[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    echo -e "\033[1;33m[*] Installing $tool...\033[0m"
    eval "${tools[$tool]}"
    
    # 🛠️ Symlink if not directly available in PATH
    if [ -f "$HOME/go/bin/$tool" ]; then
      sudo ln -sf "$HOME/go/bin/$tool" "/usr/local/bin/$tool"
    fi
  else
    echo -e "\033[1;32m[✔] $tool already installed.\033[0m"
  fi
done

echo -e "\n\033[1;32m✅ All tools installed successfully and linked to PATH!\033[0m"
echo -e "\033[1;36m✨ You can now run: ./recon.sh example.com\033[0m"

