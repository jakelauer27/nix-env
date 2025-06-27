#!/usr/bin/env bash
# Bootstrap personal override *.local.nix files and sync repo override files.
# Usage: bootstrap-overrides.sh <repo_dir> <target_dir>
# Behaviour:
#   1. For each of user.local.nix, casks.local.nix, home.local.nix:
#        • If it does NOT exist under $TARGET_DIR/local-overrides/, copy the template,
#          prompt the user, and allow them to edit later.
#        • If it exists, leave it untouched.
#   2. Copy/overwrite any repo-tracked override files (every *.nix in
#      $REPO_DIR/local-overrides/ *except* *.example and *.local.nix) into the
#      same folder inside $TARGET_DIR so the flake picks up shared overrides.
#   3. Script is idempotent – running multiple times yields the same end-state.
#
# The script will prompt the user to press Enter after each *.local.nix is
# created so they are aware they need to customise it.
set -euo pipefail

REPO_DIR="${1:?Missing repo dir argument}"
TARGET_DIR="${2:?Missing target dir argument}"

OVERRIDE_DIR="$TARGET_DIR/local-overrides"
mkdir -p "$OVERRIDE_DIR"

# ---- 1. Ensure per-developer *.local.nix files exist ------------------------

declare -A LOCAL_FILE_MSGS=(
  ["user.local.nix"]="Defines your primary macOS username & nix-darwin user account."
  ["casks.local.nix"]="Lists additional Homebrew casks you want installed."
  ["home.local.nix"]="Contains your personal Home-Manager configuration."
)

for f in "user.local.nix" "casks.local.nix" "home.local.nix"; do
  dest="$OVERRIDE_DIR/$f"
  if [[ -e "$dest" ]]; then
    echo "✓ $f already exists – keeping your customisations."
  else
    tmpl="$REPO_DIR/local-overrides/${f}.example"
    [[ ! -e "$tmpl" ]] && tmpl="$REPO_DIR/${f}.example"
    if [[ -e "$tmpl" ]]; then
      cp "$tmpl" "$dest"
    else
      echo "# Personal overrides – edit me" > "$dest"
    fi

    # Populate username in user.local.nix on macOS
    if [[ "$f" == "user.local.nix" ]]; then
      USERNAME="$(id -un)"
      USERHOME="$(eval echo ~"$USERNAME")"
      sed -i '' \
        -e "s|<your-mac-username>|$USERNAME|g" \
        -e "s|/Users/<your-mac-username>|$USERHOME|g" "$dest"
    fi

    echo "→ Created $f in $OVERRIDE_DIR"
    echo "   ${LOCAL_FILE_MSGS[$f]}"
    read -rp "Press Enter after you have reviewed and customised $f ... " _
  fi
done

# ---- 2. Sync shared override files from repo -------------------------------

shopt -s nullglob
for file in "$REPO_DIR"/local-overrides/*.nix; do
  base="$(basename "$file")"
  # Skip examples & local override templates we handled above
  if [[ "$base" == *.example || "$base" == *.local.nix ]]; then
    continue
  fi
  cp -f "$file" "$OVERRIDE_DIR/"
  echo "→ Synced shared override $base to $OVERRIDE_DIR"
done
shopt -u nullglob

echo "Bootstrap of overrides complete."
