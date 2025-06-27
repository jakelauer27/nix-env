#!/bin/bash

set -e

# Color helpers
BLU="\033[0;34m"
GRN="\033[0;32m"
YEL="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"  # No Color

# Function to check system requirements
check_system_requirements() {
  echo -e "${BLU}=== Checking System Requirements ===${NC}"
  
  # Check disk space (need at least 10GB free)
  local free_space=$(df -h / | awk 'NR==2 {print $4}')
  # Extract numeric part for comparison
  local numeric_space=$(echo "$free_space" | sed 's/[A-Za-z]//g')
  local unit=$(echo "$free_space" | sed 's/[0-9.]//g')
  
  # Convert to GB for comparison if needed
  local space_in_gb=$numeric_space
  if [[ "$unit" == "Ti" || "$unit" == "T" ]]; then
    space_in_gb=$(echo "$numeric_space * 1024" | bc)
  elif [[ "$unit" == "Mi" || "$unit" == "M" ]]; then
    space_in_gb=$(echo "$numeric_space / 1024" | bc)
  fi
  
  # Simple numeric comparison
  if (( $(echo "$space_in_gb < 10" | bc 2>/dev/null || echo 1) )); then
    echo -e "${RED}Error: Insufficient disk space. At least 10GB free space required.${NC}"
    echo -e "Current free space: $free_space"
    exit 1
  fi
  echo -e "${GRN}✓ Sufficient disk space available: $free_space${NC}"
  
  # Check for existing Nix volume and its state
  echo -e "${BLU}Checking for existing Nix volumes...${NC}"
  if diskutil list | grep -q "Nix Store"; then
    echo -e "${YEL}Found existing Nix volume.${NC}"
    echo -e "Checking volume state..."
    
    # Check if volume is properly mounted
    if ! mount | grep -q "/nix"; then
      echo -e "${YEL}Warning: Nix volume exists but is not mounted at /nix${NC}"
      echo -e "This could indicate a previous failed installation."
      
      read -p "Would you like to attempt to fix the Nix volume? (y/n) " fix_volume
      if [[ "$fix_volume" == "y" ]]; then
        echo -e "Attempting to unmount and delete the existing Nix volume..."
        sudo diskutil apfs deleteVolume "Nix Store" || echo -e "${YEL}Could not delete volume, continuing anyway...${NC}"
      fi
    fi
  else
    echo -e "${GRN}✓ No existing Nix volume found${NC}"
  fi
  
  echo -e "${GRN}✓ System checks complete${NC}"
  echo
}

# Function to run a command with timeout
run_with_timeout() {
  local timeout=$1
  local cmd="$2"
  local msg="$3"
  
  echo -e "${BLU}$msg${NC}"
  
  # Start the command in background
  eval "$cmd" &
  local cmd_pid=$!
  
  # Wait for command to finish or timeout
  local elapsed=0
  local sleep_interval=15
  while kill -0 $cmd_pid 2>/dev/null; do
    if [ $elapsed -ge $timeout ]; then
      echo -e "${RED}Command timed out after ${timeout} seconds${NC}"
      echo -e "${YEL}Killing process...${NC}"
      kill -9 $cmd_pid 2>/dev/null || true
      return 1
    fi
    
    echo -e "${YEL}Still running... (${elapsed}s/${timeout}s)${NC}"
    sleep $sleep_interval
    elapsed=$((elapsed + sleep_interval))
  done
  
  # Check if command was successful
  wait $cmd_pid
  local exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo -e "${GRN}✓ Command completed successfully${NC}"
    return 0
  else
    echo -e "${RED}Command failed with exit code $exit_code${NC}"
    return $exit_code
  fi
}

# Display information about the installation process
echo -e "${BLU}=== Nix Installation Process ===${NC}"
echo -e "This script will install or upgrade Nix on your system. The process includes:"
echo -e " ${YEL}1.${NC} Checking system requirements"
echo -e " ${YEL}2.${NC} Cleaning up any existing Nix installation"
echo -e " ${YEL}3.${NC} Creating system users for Nix builds"
echo -e " ${YEL}4.${NC} Creating and configuring a Nix volume"
echo -e " ${YEL}5.${NC} Installing Nix package manager"
echo -e " ${YEL}6.${NC} Configuring shell integration"
echo -e ""
echo -e "${YEL}Important:${NC} This process will:"
echo -e " - Require sudo access"
echo -e " - Take approximately 5-10 minutes to complete"
echo -e " - The volume creation step may appear to hang for several minutes"
echo -e " - Modify shell configuration files"
echo -e ""
read -p "Press Enter to continue or Ctrl+C to cancel..." _
echo -e ""

# Run system requirement checks
check_system_requirements

handle_backup_files() {
  local file="$1"
  local backup="${file}.backup-before-nix"
  local force="$2"
  
  if [ -f "$backup" ]; then
    echo "⚠️  Found existing backup file: $backup"
    echo "📋 Creating temporary backup of current files..."
    sudo cp "$file" "${file}.temp-$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    sudo cp "$backup" "${backup}.temp-$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    
    echo "🔍 Checking if backup contains Nix-related content..."
    if sudo grep -q "nix" "$backup" 2>/dev/null; then
      echo "⚠️  Warning: Backup file contains Nix-related content."
      if [ "$force" = "force" ]; then
        echo "🔥 Force option specified - removing problematic backup file"
        sudo rm -f "$backup"
        echo "✅ Removed problematic backup file: $backup"
      else
        echo "⚠️  This suggests a previous installation issue."
        echo "⚠️  Keeping both files for safety."
      fi
    else
      echo "✅ Backup file looks clean (no Nix references)."
      echo "🔄 Restoring original backup file to $file"
      sudo mv "$backup" "$file"
    fi
  fi
}

echo "🔁 Preparing for Nix installation..."

# Handle backup files before uninstallation
handle_backup_files "/etc/bashrc"
handle_backup_files "/etc/zshrc"
handle_backup_files "/etc/bash.bashrc" "force"

echo "🔁 Uninstalling existing Nix..."
rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nixpkgs ~/.cache/nix
sudo rm -rf /etc/nix /etc/profile.d/nix.sh /etc/static/bashrc /Library/LaunchDaemons/org.nixos.nix-daemon.plist

echo "🧹 Removing nix-related shell config from ~/.zshrc and ~/.bash_profile..."
sed -i '' '/nix/d' ~/.zshrc 2>/dev/null || true
sed -i '' '/nix/d' ~/.bash_profile 2>/dev/null || true

echo "✅ Clean slate. Now reinstalling Nix (multi-user mode)..."

# Download the installer script first
echo "📥 Downloading Nix installer..."
curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh

# Run the installer with a timeout
if ! run_with_timeout 600 "sh /tmp/nix-install.sh --daemon" "Installing Nix (this may take up to 10 minutes)..."; then
  echo -e "${RED}Error: Nix installation timed out after 10 minutes.${NC}"
  echo -e "${YEL}This could be due to issues with volume creation or mounting.${NC}"
  echo -e "Checking for partial installation..."
  
  # Check if nix command exists despite timeout
  if command -v nix >/dev/null 2>&1; then
    echo -e "${GRN}Nix command is available despite timeout.${NC}"
    echo -e "Proceeding with configuration..."
  else
    echo -e "${RED}Nix installation failed. Please try again or install manually.${NC}"
    exit 1
  fi
fi

echo "🔧 Enabling flakes and nix-command globally..."
sudo mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" | sudo tee /etc/nix/nix.conf

echo "🔁 Restarting nix-daemon..."
if ! run_with_timeout 60 "sudo launchctl kickstart -k system/org.nixos.nix-daemon" "Restarting nix-daemon..."; then
  echo -e "${YEL}Warning: Could not restart nix-daemon, trying alternative method...${NC}"
  sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
  sleep 2
  sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
fi

# Verify installation
echo "🔍 Verifying Nix installation..."
if command -v nix >/dev/null 2>&1; then
  echo -e "${GRN}✅ Nix successfully installed!${NC}"
  echo -e "Nix version: $(nix --version)"
  echo -e "${GRN}✅ Nix multi-user installed with flakes enabled!${NC}"
  echo -e "👉 Try running: nix flake show github:NixOS/nixpkgs"
else
  echo -e "${RED}Error: Nix installation verification failed.${NC}"
  echo -e "Please check the logs above for errors and try again."
  exit 1
fi

