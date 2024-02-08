## My Development Environment Ansible Playbook

### Run playbook

```bash
 ansible-playbook dev_env_setup.yml --ask-become-pass --ask-vault-pass
```

This Ansible playbook sets up a development environment on a local machine with various tools and configurations. Below is an overview of the tasks performed by the playbook:

All configurations are applied for my 3 users.

- Setup APT repositories
- Install required packages
- Create symbolic links for configuration files
- Setup ZSH shell with Oh My Zsh, Powerlevel10k theme, and zsh-autosuggestions, fzf
- Setup tmux
- Download and setup FiraCode Nerdfont
- Setup Neovim with packer.nvim and additional configurations
- Install .NET
- Install docker

### Manual steps:

- Create the 3 users
- Install Rider
- Install gnome extensions ([Gnome Extensions](https://extensions.gnome.org/))
     - sound-output-device-chooser
     - Vitals
     - unite
     - user-theme

### TODO:
- [ ] Install lazygit and lazydocker
- [ ] Make ansible files work with Arch
- [ ] Save sway config  
- [ ] Screenshot stuff
    - grim, slurp, wl-copy
