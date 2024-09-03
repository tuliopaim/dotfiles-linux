{ pkgs, ... }:
{
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

        # yazi image preview
        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM
        
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
        
        bind-key -r F run-shell "tmux neww -t 99 tmux-sessionizer"
        bind-key -r f run-shell "tmux neww -t 99 tmux-windownizer"
        bind-key -r H run-shell "tmux-dotfiles"
        
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
