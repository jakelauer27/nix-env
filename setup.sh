#!/usr/bin/env bash
# Main setup script for Whitepages developer environment using nix-darwin.
# This script is idempotent – it can be run multiple times safely.
# It orchestrates the full setup process from Nix installation to repository cloning.
#
# Usage:
#   ./setup.sh             # Skip Nix installation, just set up nix-darwin config
#   ./setup.sh --install-nix  # Include Nix installation/upgrade (takes 5-10 minutes)

set -euo pipefail

# Parse command line arguments
INSTALL_NIX=false
for arg in "$@"; do
  case $arg in
    --install-nix)
      INSTALL_NIX=true
      ;;
  esac
done

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

# Ensure Homebrew is installed before anything else
bash "$REPO_DIR/setup-scripts/install-brew.sh"

# Directory where the active nix-darwin flake will live (standard path expected by most docs)
NIX_DIR="$HOME/.config/nix-darwin"
mkdir -p "$NIX_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Color helpers
BLU="\033[0;34m"
GRN="\033[0;32m"
YEL="\033[0;33m"
NC="\033[0m"  # No Color

log_step() {
  echo -e "${BLU}→ $1${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. Install / upgrade Nix (optional, only if --install-nix flag is provided)
if [ "$INSTALL_NIX" = true ]; then
  log_step "1. Installing or upgrading Nix (may prompt for sudo)…"
  bash "$REPO_DIR/setup-scripts/install-nix.sh"
else
  log_step "1. Skipping Nix installation (use --install-nix flag to include this step)"
  # Check if nix is available
  if ! command -v nix >/dev/null 2>&1; then
    echo -e "${YEL}Warning: Nix does not appear to be installed.${NC}"
    echo -e "You may need to run this script with the --install-nix flag first."
    exit 1
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 2. Bootstrap core flake files
log_step "2. Bootstrapping core nix-darwin flake files…"
bash "$REPO_DIR/setup-scripts/bootstrap-core.sh" "$REPO_DIR" "$NIX_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# 3. Bootstrap personal overrides
log_step "3. Bootstrapping personal override files…"
bash "$REPO_DIR/setup-scripts/bootstrap-overrides.sh" "$REPO_DIR" "$NIX_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# 4. Build & activate nix-darwin configuration
log_step "4. Building & switching nix-darwin configuration…"
bash "$REPO_DIR/setup-scripts/activate-nix-darwin.sh" "$NIX_DIR"
