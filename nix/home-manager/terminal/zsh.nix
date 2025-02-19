{ pkgs, config, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "ls -la";
      update = "sudo nixos-rebuild switch --flake ~/.dotfiles/nix";
      ".." = "cd ..";
      "...." = "cd ../..";
      "......" = "cd ../../..";
      sshtb = "eval \"$(ssh-agent -s)\" && ssh-add ~/.ssh/id_tb_gh";
      sshpersonal = "eval \"$(ssh-agent -s)\" && ssh-add ~/.ssh/id_personal_gh";
      lg = "lazygit";
      lz = "lazydocker";
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
      export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix -H'

      export FZF_ALT_C_COMMAND="fd --type d . -H --strip-cwd-prefix"
      export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

      export PATH="~/.local/bin:$PATH"

      export PATH=$PATH:/home/$USER/.dotnet:~/.dotnet/tools

      function yy() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      function killp(){
          ps aux | fzf --height 40% --layout=reverse --prompt="Select a process to kill: " | awk '{print $2}' | xargs -r sudo kill
      }

      eval "$(zoxide init zsh)"
    '';
  };
}
