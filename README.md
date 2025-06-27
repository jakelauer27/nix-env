# Whitepages Developer Setup for macOS

This repository contains a standardized macOS development environment setup using [nix-darwin](https://github.com/LnL7/nix-darwin) and [Home Manager](https://github.com/nix-community/home-manager). It provides a declarative, reproducible configuration that ensures all developers have a consistent environment with the tools they need.

## Quick Start

1. Clone this repository:

2. Run the setup script:
   ```bash
   # If Nix is already installed:
   ./setup.sh

   # If Nix is NOT installed or needs upgrading (takes 5-10 minutes):
   ./setup.sh --install-nix

   # Combine flags as needed:
   ./setup.sh --install-nix
   ```

   > **Note:**
   > - The `--install-nix` flag is only needed for initial setup or when you want to upgrade Nix. The Nix installation process takes 5-10 minutes and requires sudo access.

## What the Setup Script Does

The `setup.sh` script automates the entire developer onboarding process:

1. **Installs Nix** - Sets up the Nix package manager with multi-user mode and flakes support
2. **Bootstraps core configuration** - Copies essential nix-darwin configuration files to `~/.config/nix-darwin`
3. **Creates personal overrides** - Sets up your personalized configuration files with your username
4. **Builds and activates** - Runs `nix-darwin switch` to apply the configuration to your system - installing all the standard developer tools and applications.

This approach offers several benefits:
- **Reproducible environment** - Every developer gets the same tools and configurations
- **Declarative configuration** - All software and settings are defined in code
- **Isolation** - Nix keeps dependencies isolated to avoid conflicts
- **Easy updates** - Pull the latest changes and run setup.sh again to update

---

### Adding Your Own Aliases and Functions

To add your own aliases and functions, edit your personal override file at:
```
~/.config/nix-darwin/local-overrides/home.local.nix
```

After making changes, rebuild your configuration with:
```bash
nixos-rebuild
```

## Customizing Your Local Setup

This setup uses a layered approach to configuration. The base configuration is shared among all developers, while personal customizations are kept in override files. These override files are not tracked in the main repository, allowing you to make personal changes without affecting others.

After running the setup script, you can customize your environment by editing the following files in `~/.config/nix-darwin/local-overrides/`:

### `user.local.nix` - User Account Settings

This file contains your user-specific settings like username and home directory. Example:

```nix
{ config, pkgs, ... }:
{
  # Override the default user
  system.primaryUser = "yourusername";
  
  # Other user-specific system settings
  system.defaults.dock.autohide = true;
}
```

### `home.local.nix` - Personal Home Manager Configuration

This file manages your personal dotfiles, shell configuration, aliases, and environment variables. Example:

```nix
{ config, pkgs, ... }:
{
  # Your personal username and home directory
  home.username = "yourusername";
  home.homeDirectory = "/Users/yourusername";
  
  # Personal shell aliases
  home.shellAliases = {
    projects = "cd ~/Projects";
    wp = "cd ~/Projects/Whitepages";
  };
  
  # Personal environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    OPEN_API_KEY = "your-api-key";
  };
  
  # Custom shell initialization
  programs.zsh.initContent = ''
    # Your custom shell initialization code here
    [ -f "$HOME/.zsh_sgpt_widget.zsh" ] && source "$HOME/.zsh_sgpt_widget.zsh"
  '';
}
```

### `casks.local.nix` - Additional macOS Applications

This file lets you specify additional macOS applications to install via Homebrew casks. Example:

```nix
{ pkgs, ... }:
{
  homebrew = {
    casks = [
      "spotify"
      "rectangle"
      "obsidian"
      "logi-options-plus"
    ];
    
    # Additional Homebrew packages (CLI tools)
    brews = [
      "muteme"
    ];
  };
}
```

### Applying Your Changes

After making changes to any of these files, apply them with the `nixos-rebuild` alias or run:

```bash
cd ~/.config/nix-darwin && sudo nix run github:lnl7/nix-darwin -- switch --flake .
```

## Troubleshooting

If you encounter issues during setup:

1. Check the error messages for specific problems
2. Try running the setup script again (it's idempotent)
3. Reach out to the DevOps team for assistance

## Contributing

Improvements to this setup are welcome! This repository is designed to be the standard development environment for all Whitepages engineers, so contributions that enhance productivity across the team are encouraged.

### Contribution Workflow

1. **Fork or Branch**: Create a branch from the main repository.

2. **Make Your Changes**: Modify the shared configuration files:
   - `darwin-configuration.nix` - For system-wide packages and settings
   - `home.nix` - For shared shell configuration and aliases
   - `setup.sh` and scripts in `setup-scripts/` - For setup automation

3. **Test Locally**: Test your changes by running the setup script:
   ```bash
   ./setup.sh
   ```
   The script is idempotent, so it's safe to run multiple times. This will apply your changes to your local environment.

4. **Update Documentation**: If you're adding new features or tools:
   - Add them to the appropriate section in the README
   - Include a brief explanation of what they are and why they're useful

5. **Submit a Pull Request**: Include in your PR description:
   - What problem your change solves
   - How it benefits the team
   - Any manual testing you've performed

### Guidelines for Good Contributions

- **Keep it Minimal**: Only add tools and configurations that benefit most developers
- **Document Everything**: Ensure new tools are well-documented in the README
- **Maintain Idempotence**: All scripts should be safe to run multiple times
- **Respect Local Overrides**: Don't force settings that should be personal preferences
- **Test on Clean Systems**: When possible, test on a fresh macOS installation
