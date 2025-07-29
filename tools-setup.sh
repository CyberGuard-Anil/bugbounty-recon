#!/bin/bash

set -euo pipefail

INSTALL_PATH="$HOME/go/bin"
LINK_PATH="/usr/local/bin"

install_go_tool() {
    local pkg=$1
    local binname=$2
    if command -v "$binname" &>/dev/null; then
        echo "$binname already installed."
        return
    fi
    echo "Installing $binname..."
    GO111MODULE=on go install "$pkg@latest"
    if [[ ! -f "$INSTALL_PATH/$binname" ]]; then
        echo "Failed to install $binname via go install."
        exit 1
    fi
    sudo ln -sf "$INSTALL_PATH/$binname" "$LINK_PATH/$binname"
}

install_naabu() {
    if command -v naabu &>/dev/null; then
        echo "naabu already installed."
        return
    fi

    echo "Installing naabu (auto-patch if needed)..."
    if GO111MODULE=on go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest 2>&1 | tee /tmp/naabu-install.log; then
        echo "naabu installed via go install."
    elif grep -q "invalid go version" /tmp/naabu-install.log; then
        echo "Detected go.mod version error, applying patch..."
        tmpdir=$(mktemp -d)
        git clone https://github.com/projectdiscovery/naabu.git "$tmpdir/naabu"
        cd "$tmpdir/naabu/v2"
        sed -i 's/go 1\.24\.0/go 1.24/' go.mod
        cd cmd/naabu
        go install .
        cd -
        rm -rf "$tmpdir"
        echo "naabu installed from patched source."
    else
        echo "Failed to install naabu. Check /tmp/naabu-install.log"
        exit 1
    fi

    if [[ -f "$INSTALL_PATH/naabu" ]]; then
        sudo ln -sf "$INSTALL_PATH/naabu" "$LINK_PATH/naabu"
    fi
}

echo "Checking Go installation..."
if ! command -v go &>/dev/null; then
    echo "Go not found, please install Go first!"
    exit 1
fi

sudo apt update
sudo apt install -y libpcap-dev

echo "Installing subfinder, httpx, ffuf..."
install_go_tool "github.com/projectdiscovery/subfinder/v2/cmd/subfinder" "subfinder"
install_go_tool "github.com/projectdiscovery/httpx/cmd/httpx" "httpx"
install_go_tool "github.com/ffuf/ffuf" "ffuf"

install_naabu

# Add Go bin to PATH if missing
if ! echo "$PATH" | grep -q "$HOME/go/bin"; then
    echo "export PATH=\$PATH:$HOME/go/bin" >> ~/.bashrc
    export PATH="$PATH:$HOME/go/bin"
    echo "Added $HOME/go/bin to your PATH (in ~/.bashrc). Please restart your shell or run 'source ~/.bashrc'."
fi

echo "All tools installed and linked!"

