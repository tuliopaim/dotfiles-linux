{ outputs, config, pkgs, pkgs-unstable, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/" + username;

  home.stateVersion = "24.05";

  imports = [
    ../../home-manager/hyprland
    ../../home-manager/apps
    ../../apps/zsh.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
      packageOverrides = pkgs: {
        dotnet-ef = pkgs.callPackage ../../apps/dotnet-ef/default.nix { inherit pkgs; };
      };
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = with pkgs; [

    # langs
    (lib.hiPrio gcc)
    (lib.lowPrio clang)
    cargo
    nodejs
    (with dotnetCorePackages; combinePackages [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ])
    dotnet-ef

    # dev tools
    pkgs-unstable.neovim
    docker
    docker-compose
    awscli
    aws-sam-cli
    terraform
    jetbrains.rider
    postman
    netcoredbg

    # scripts 
    (pkgs.writeShellScriptBin "clone-wt" (builtins.readFile ../../../scripts/clone-wt))
    (pkgs.writeShellScriptBin "prune-wt" (builtins.readFile ../../../scripts/prune-wt))
    (pkgs.writeShellScriptBin "tmux-sessionizer" (builtins.readFile ../../../scripts/tmux-sessionizer))
    (pkgs.writeShellScriptBin "lockscreentime" (builtins.readFile ../../../scripts/lockscreentime))
    (pkgs.writeShellScriptBin "usersecrets" (builtins.readFile ../../../scripts/usersecrets))
    (pkgs.writeShellScriptBin "connect-vpn" (builtins.readFile ../../../scripts/connect-vpn))
    (pkgs.writeShellScriptBin "disconnect-vpn" (builtins.readFile ../../../scripts/disconnect-vpn))
  ];

  home.file = {
    ".ideavimrc".source = ../../../ideavim/.ideavimrc;
  };

  programs = {
    home-manager = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      enable = true;
    };
  };
}
