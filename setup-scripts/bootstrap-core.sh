#!/usr/bin/env bash
# Bootstrap core nix-darwin configuration files into the user's ~/.config/nix-darwin directory.
# Usage: bootstrap-core.sh <repo_dir> <target_dir>

set -euo pipefail

REPO_DIR="${1:?Missing repo dir argument}"
TARGET_DIR="${2:?Missing target dir argument}"

mkdir -p "$TARGET_DIR"

echo "→ Ensuring base configuration exists in $TARGET_DIR"

for f in darwin-configuration.nix flake.nix flake.lock home.nix; do
  cp -f "$REPO_DIR/$f" "$TARGET_DIR/"
  if [[ "$f" == "flake.nix" ]]; then
    USERNAME="$(id -un)"
    sed -i '' -e "s/<username>/$USERNAME/g" "$TARGET_DIR/flake.nix"
  fi
  echo "→ Synced $f to $TARGET_DIR"
done
