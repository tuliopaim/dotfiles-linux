{ config, pkgs, ... }:

{
  home.username = "tuliopaim";
  home.homeDirectory = "/home/tuliopaim";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.packages = with pkgs; [
      # langs
      (lib.hiPrio gcc)
      (lib.lowPrio clang)
      cargo
      nodejs
      dotnetCorePackages.sdk_6_0_1xx

      # terminal tools
      wget
      fd
      fzf
      htop
      ripgrep
      tree
      unzip
      zip
      zoxide
      wl-clipboard
      grim
      slurp
      swappy
      copyq
      ansible
      stow
      lazygit
      killall

      #hyprland
      swww
      waybar
      rofi-wayland
      gnome-icon-theme
      pulseaudio
      fira-code-nerdfont
      swaylock
      wlogout
      
      # desktop
      cinnamon.nemo-with-extensions
      neovim
      brave
      firefox
      microsoft-edge
      spotify
      slack
      obsidian
      pavucontrol
      vlc
      discord
      networkmanagerapplet
      os-prober
      openfortivpn
  ];

  home.file = {
      ".local/bin" =
      {
          source = config.lib.file.mkOutOfStoreSymlink "../scripts";
          recursive = true;
      };
  };

  home.sessionVariables = {
     EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
	  enable = true;
	  enableCompletion = true;
	  autosuggestion.enable = true;
	  syntaxHighlighting.enable = true;

	  shellAliases = {
		  ls = "ls -la";
		  update = "sudo nixos-rebuild switch";
		  ".." = "cd ..";
		  "...." = "cd ../..";
		  "......" = "cd ../../..";
		  sshtb = "eval \"$(ssh-agent -s)\" && ssh-add ~/.ssh/id_tb_gh";
		  sshpersonal = "eval \"$(ssh-agent -s)\" && ssh-add ~/.ssh/id_personal_gh";
		  lg = "lazygit";
		  cd = "z";
	  };

	  history = {
		  size = 10000;
		  path = "${config.xdg.dataHome}/zsh/history";
	  };

	  oh-my-zsh = {
		  enable = true;
		  plugins = [ "git" "vi-mode" ];
		  theme = "amuse";
	  };

      initExtra = ''
          export FZF_DEFAULT_OPTS="--color=16 --color=fg+:#FF5E7D --color=bg+:#002B36 --color=hl:#B48EAD --color=fg:#839496"
          export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'

          export FZF_ALT_C_COMMAND="fd --type d . --strip-cwd-prefix"
          export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

          eval "$(zoxide init zsh)"
      '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    escapeTime = 0;

    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.yank
      tmuxPlugins.resurrect
      tmuxPlugins.yank
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.catppuccin
    ];

    extraConfig = ''

        # set prefix
        unbind C-b
        set -g prefix C-s
        bind C-s send-prefix
        
        set-option -g mouse on
        
        # fix colors
        set -sa terminal-overrides ",xterm*:Tc"
        
        # Set 'v' for vertical and 'h' for horizontal split
        bind v split-window -h -c '#{pane_current_path}'
        bind b split-window -v -c '#{pane_current_path}'
        
        #vim key maps
        setw -g mode-keys vi
        
        # Smart pane switching with awareness of vim and fzf
        forward_programs="view|n?vim?|fzf"
        
        should_forward="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?($forward_programs)(diff)?$'"
        
        bind -n C-h if-shell "$should_forward" "send-keys C-h" "select-pane -L"
        bind -n C-j if-shell "$should_forward" "send-keys C-j" "select-pane -D"
        bind -n C-k if-shell "$should_forward" "send-keys C-k" "select-pane -U"
        bind -n C-l if-shell "$should_forward" "send-keys C-l" "select-pane -R"
        bind -n C-\\ if-shell "$should_forward" "send-keys C-\\" "select-pane -l"
        
        # vim-like pane switching
        bind -r k select-pane -U 
        bind -r j select-pane -D 
        bind -r h select-pane -L
        bind -r l select-pane -R 
        
        # vim-like pane resizing  
        bind -r C-k resize-pane -U
        bind -r C-j resize-pane -D
        bind -r C-h resize-pane -L
        bind -r C-l resize-pane -R
        
        # vim-like window switching
        bind -n M-H previous-window 
        bind -n M-L next-window 
        
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        
        bind-key -r f run-shell "tmux neww ~/.local/bin/tmux-sessionizer"
        
        bind-key -r H run-shell "~/.local/bin/tmux-sessionizer ~/dev/tb/ems"
        
        # remove default binding since replacing
        unbind %
        unbind Up
        unbind Down
        unbind Left
        unbind Right
        
        unbind C-Up
        unbind C-Down
        unbind C-Left
        unbind C-Right

        set -g @catppuccin_flavour 'mocha'
    '';

  };

}
