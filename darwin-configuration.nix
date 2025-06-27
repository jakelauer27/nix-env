{ config, pkgs, inputs, lib, ... }:

{
  imports =
    [ inputs.home-manager.darwinModules.home-manager ]
    ++ [ ./local-overrides/user.local.nix ./local-overrides/casks.local.nix ];

  # Provide a default primaryUser if not set by overrides
  system.primaryUser = lib.mkDefault (builtins.getEnv "USER");

  system.stateVersion = 4;
  ids.gids.nixbld = 350;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    direnv
    pyenv
    python3
    git-crypt
    kubectl
    awscli2
    terraform
    pipenv
    poetry
    curl
    wget
    jq
    netcat
    nmap
    docker-compose
    tree
    ripgrep
    fd
    fzf
    tmux
    unzip
    zip
    gnupg
    black
    pylint
    nodejs
    # yarn removed - using corepack instead
    corepack
    bat
    neovim
    gh
    lazygit
    direnv
    devenv
    starship
    # GUI apps are now managed by Homebrew below
  ];

  programs.zsh.enable = true;

  # Enable corepack system-wide
  environment.shellInit = ''
    export COREPACK_ENABLE_STRICT=0
    if command -v corepack >/dev/null 2>&1; then
      corepack enable >/dev/null 2>&1 || true
    fi
  '';

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;



  # Enable Homebrew and install GUI apps as casks
  # Plus CLI tools that are not available in nixpkgs
  homebrew = {
    enable = true;
    taps = [
      "ankitpokhrel/jira-cli"
    ];
    brews = [
      "helm"
      "jira-cli"
      "bitwarden-cli"
      "pipx"
    ];
    casks = [
      "postman"
      "pgadmin4"
      "bitwarden"
      "figma"
      "google-chrome"
      "warp"
      "windsurf"
      "docker"
      "chatgpt"
      "muteme"
      "rectangle"
      "spotify"
      "obsidian"
      "logi-options-plus"
    ];
  };
}
