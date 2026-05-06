#!/bin/bash

# Detect the shell
SHELL_NAME=$(basename "$SHELL")

case "$SHELL_NAME" in
    "bash")
        echo "Bash shell detected"
        ;;
    "zsh")
        echo "Zsh shell detected"
        ;;
    "fish")
        echo "Fish shell detected"
        ;;
    *)
        echo "Unsupported shell: $SHELL_NAME"
        exit 1
        ;;
esac

# Step 1: Identify the operating system
OS=""
case "$OSTYPE" in
    "linux-android"*)
        OS="android"
        ;;
    "linux-"*)
        OS="linux"
        ;;
    "darwin"*)
        OS="darwin"
        ;;
    *)
        echo "Unsupported operating system: $OSTYPE"
        exit 1
        ;;
esac

echo "Step 1: Identified operating system as $OS"

# Step 2: Identify processor architecture
ARCH=$(uname -m)

case $ARCH in
    "x86_64")
        ARCH="amd64"
        ;;
    "aarch64" | "arm64")
        ARCH="arm64"
        ;;
    "i386" | "i686")
        ARCH="386"
        ;;
    "arm"*)
        ARCH="arm"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Step 2: Identified processor architecture as $ARCH"


# Step 3: Fetch latest pre-release binary from GitHub
REPO="atanuroy22/jiotv_go"
API_URL="https://api.github.com/repos/$REPO/releases"

echo "Fetching latest prerelease..."

JSON=$(curl -s -H "User-Agent: jiotv-installer" "$API_URL")

# detect target binary name
TARGET="jiotv_go-android-$ARCH"

ASSET_URL=$(echo "$JSON" | grep -oE '"prerelease":[ ]*true|false|"browser_download_url":[ ]*"[^"]+"' \
| awk -v target="$TARGET" '
BEGIN { prerelease=0; url="" }

{
    if ($0 ~ /"prerelease":[ ]*true/) {
        prerelease=1
    }

    if (prerelease == 1 && $0 ~ /browser_download_url/) {
        match($0, /"browser_download_url":[ ]*"([^"]+)"/, a)
        url=a[1]

        if (url ~ target) {
            print url
            exit
        }
    }
}
')

if [[ -z "$ASSET_URL" ]]; then
    echo "No prerelease binary found for $TARGET"
    exit 1
fi

echo "Latest prerelease download:"
echo "$ASSET_URL"

if [[ -z "$ASSET_URL" ]]; then
    echo "Failed to find matching binary for $OS-$ARCH"
    exit 1
fi

echo "Downloading from: $ASSET_URL"

# If any existing binary is present, delete it
if [[ -f "jiotv_go" ]]; then
    rm jiotv_go
fi

curl -SL --progress-bar --retry 2 --retry-delay 2 -o jiotv_go "$ASSET_URL" || {
    echo "Failed to download binary"
    exit 1
}

# Step 4: Give executable permissions
chmod +x jiotv_go
echo "Step 4: Granted executable permissions to the binary"

# Step 5: Move binary to $HOME/.jiotv_go/bin
if [[ ! -d "$HOME/.jiotv_go" ]]; then
    mkdir -p "$HOME/.jiotv_go"
fi
if [[ ! -d "$HOME/.jiotv_go/bin" ]]; then
    mkdir -p "$HOME/.jiotv_go/bin"
fi
mv jiotv_go "$HOME/.jiotv_go/bin"
echo "Step 5: Moved the binary to $HOME/.jiotv_go/bin"

# Step 6: Add $HOME/.jiotv_go to PATH
case "$SHELL_NAME" in
    "bash")
        export PATH="$PATH:$HOME/.jiotv_go/bin"
        echo "export PATH=$PATH:$HOME/.jiotv_go/bin" >> "$HOME/.bashrc"
        ;;
    "zsh")
        export PATH=$PATH:$HOME/.jiotv_go/bin
        echo "export PATH=$PATH:$HOME/.jiotv_go/bin" >> "$HOME/.zshrc"
        ;;
    "fish")
        echo "set -gx PATH $PATH $HOME/.jiotv_go/bin" >> "$HOME/.config/fish/config.fish"
        echo "Please restart your terminal or run source $HOME/.config/fish/config.fish"
        ;;
    *)
        echo "Unsupported shell: $SHELL_NAME"
        exit 1
        ;;
esac

# Step 7: Inform the user
echo "JioTV Go has successfully installed. Restart your terminal and start by running \"jiotv_go help\""
