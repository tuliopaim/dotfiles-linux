## My Development Environment Ansible Playbook

## Usage

### Clone repo

``` bash
git clone --recurse-submodules https://github.com/tuliopaim/dotfiles-wsl.git
```

### Install ansible

``` bash
sudo apt update && sudo apt install ansible -y
```

### Run playbook

```bash
 ansible-playbook dev_env_setup.yml --ask-become-pass --ask-vault-pass
```

This Ansible playbook sets up a development environment on a local machine with various tools and configurations. Below is an overview of the tasks performed by the playbook:

- Setup APT repositories
- Install required packages
- Setup SSH keys
- Create symbolic links for configuration files
- Setup ZSH shell with Oh My Zsh, Powerlevel10k theme, and zsh-autosuggestions
- Setup Neovim with packer.nvim and additional configurations
