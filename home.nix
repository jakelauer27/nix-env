{ config, pkgs, ... }:
{
  # Each developer **must** create a git-ignored `home.local.nix` with their
  # personal username, homeDirectory, secrets, aliases, etc.
  imports = [ ./local-overrides/home.local.nix ];

  home.stateVersion = "23.11";

  programs.zsh = {
    enable = true;
    initContent = ''
      eval "$(direnv hook zsh)"
    '';
  };

  # Enable direnv and nix-direnv for all users
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Aliases we want every developer to have
  home.shellAliases = {
    # Directory nav
    ".."   = "cd ..";
    "..."  = "cd ../..";
    "...." = "cd ../../..";

    # Listing
    ls = "ls -G";
    ll = "ls -lh";
    la = "ls -lha";
    l  = "ls -CF";

    # Git helpers
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";

    # Misc / tooling
    h      = "history";
    grep   = "grep --color=auto";
    df     = "df -h";
    du     = "du -h";
    k      = "kubectl";
    refresh = "source ~/.zshrc";
    pip     = "pip3";

    nixos-rebuild = "cd ~/.config/nix-darwin && sudo nix run github:lnl7/nix-darwin -- switch --flake .";
    aws_login     = "aws sso login --sso-session engineering";
  };

  # Environment variables that should exist for everyone
  home.sessionVariables = {
    NVM_DIR    = "$HOME/.nvm";
    SDKMAN_DIR = "$HOME/.sdkman";
    PATH       = "/usr/local/opt/helm@2/bin:$HOME/.codeium/windsurf/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH";
  };
}
