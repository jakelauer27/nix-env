#!/usr/bin/env bash
# Installs Homebrew if it is not already installed.
# Safe to run multiple times.

set -euo pipefail

if command -v brew >/dev/null 2>&1; then
  echo "✓ Homebrew is already installed."
  exit 0
fi

echo "🍺 Homebrew not found. Installing Homebrew..."

NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add brew to PATH for the current shell session
if [[ -d "/opt/homebrew/bin" ]]; then
  eval "$('/opt/homebrew/bin/brew' shellenv)"
elif [[ -d "/usr/local/bin" ]]; then
  eval "$('/usr/local/bin/brew' shellenv)"
fi

echo "✓ Homebrew installation complete."
