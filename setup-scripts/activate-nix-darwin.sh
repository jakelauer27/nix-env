#!/usr/bin/env bash
# Activates (builds & switches) the nix-darwin configuration, with robust error handling.
# Usage: ./activate-nix-darwin.sh <NIX_DIR>

set -euo pipefail

NIX_DIR="${1:-$HOME/.config/nix-darwin}"
YEL="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"

log() {
  echo -e "$1"
}

log "→ Building & switching nix-darwin configuration…"

# Ensure /etc/nix/nix.conf has experimental features enabled
if ! grep -q '^experimental-features =.*nix-command.*flakes' /etc/nix/nix.conf 2>/dev/null; then
  log "${YEL}Adding experimental-features = nix-command flakes to /etc/nix/nix.conf...${NC}"
  echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
fi

# Restart nix-daemon to pick up config changes
sudo launchctl kickstart -k system/org.nixos.nix-daemon 2>/dev/null || true

pushd "$NIX_DIR" >/dev/null

set +e
SWITCH_LOG=$(mktemp)
sudo nix run --extra-experimental-features 'nix-command flakes' github:lnl7/nix-darwin -- switch --flake . 2>&1 | tee "$SWITCH_LOG"
SWITCH_EXIT=${PIPESTATUS[0]}
set -e
SWITCH_OUTPUT=$(cat "$SWITCH_LOG")
rm -f "$SWITCH_LOG"

if [[ $SWITCH_EXIT -ne 0 && "$SWITCH_OUTPUT" == *"Unexpected files in /etc"* && "$SWITCH_OUTPUT" == *"/etc/nix/nix.conf"* ]]; then
  log "${YEL}Detected unexpected /etc/nix/nix.conf. Moving it aside and retrying...${NC}"
  sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
  set +e
  RETRY_LOG=$(mktemp)
  sudo nix run --extra-experimental-features 'nix-command flakes' github:lnl7/nix-darwin -- switch --flake . 2>&1 | tee "$RETRY_LOG"
  RETRY_EXIT=${PIPESTATUS[0]}
  set -e
  RETRY_OUTPUT=$(cat "$RETRY_LOG")
  rm -f "$RETRY_LOG"
  if [[ $RETRY_EXIT -ne 0 ]]; then
    log "${RED}nix-darwin switch failed after retry. Output above.${NC}"
    popd >/dev/null
    exit 1
  fi
else
  if [[ $SWITCH_EXIT -ne 0 ]]; then
    log "${RED}nix-darwin switch failed. Output above.${NC}"
    popd >/dev/null
    exit 1
  fi
fi

popd >/dev/null
