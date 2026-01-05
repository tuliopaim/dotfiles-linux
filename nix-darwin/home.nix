{ username, pkgs, config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in

{
  home.username = username;
  home.homeDirectory = "/Users/" + username;
  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = [
    # langs
    pkgs.cargo
    pkgs.yarn
    pkgs.go
    pkgs.gopls
    pkgs.nixd

    # dev tools
    pkgs.terraform
    pkgs.postgresql
    pkgs.postgresql_jdbc

    # dotnet stuff
    pkgs.netcoredbg

    # cli tools
    pkgs.jq
    pkgs.fd
    pkgs.bat
    pkgs.ripgrep
    pkgs.eza
    pkgs.fzf
    pkgs.zoxide
    pkgs.lazygit
    pkgs.lazydocker
    pkgs.jujutsu
    pkgs.glow
    pkgs.wget
    pkgs.unzip
    pkgs.zip
    pkgs.tree
    pkgs.stow
    pkgs.fastfetch
    pkgs.age
    pkgs.pngpaste
    pkgs.gdu
    pkgs.yazi
    pkgs.p7zip
    pkgs.mercurial
    pkgs.imagemagick
    pkgs.clipboard-jh
    pkgs.gnumake
    pkgs.typescript
    pkgs.nodePackages."@angular/cli"
    pkgs.awscli2
    pkgs.gh
    pkgs.sesh
    pkgs.nmap
  ];

  # 1. Enable Home Manager to manage Zsh (Replaces Brew zsh plugins)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # You can still source your dotfiles zshrc here if you want extra custom logic
    initContent = ''
      source ${dotfilesDir}/zsh/.zshrc
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    extraConfig = ''
      source-file ${dotfilesDir}/tmux/.tmux.conf
    '';
  };

  # 2. Define Symlinks (The "Script" replacement)
  xdg.configFile = {
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nvim";
    "ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/ghostty";
    "aerospace".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/aerospace";
  };

  home.file = {
    ".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/ideavim/.ideavimrc";

    # VSCode / Cursor Symlinks
    "Library/Application Support/Cursor/User/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/vscode/Code/User/settings.json";
    "Library/Application Support/Cursor/User/keybindings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/vscode/Code/User/keybindings.json";
  };

  programs.home-manager.enable = true;
}
