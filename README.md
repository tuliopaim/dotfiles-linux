# Dotfiles for WSL

## Usage

### Install ansible

``` bash
sudo apt update && sudo apt install ansible -y
```

### Run playbook

```bash
 ansible-playbook dev_env_setup.yml --ask-become-pass --ask-vault-pass
```

This Ansible playbook sets up a .NET Core development environment on a WSL (Windows Subsystem for Linux) instance. It will perform the following steps:

- Install the required packages such as htop, curl, tree, bash-completion, make, python3-pip, zsh, neovim, git, unzip, gcc, fonts-firacode, ruby, and ruby-dev.
- Copy the private and public GitHub SSH keys to the appropriate location in the user's home directory.
- Create symbolic links for the .gitconfig file.
- Install and configure ZSH as the default shell, including installing Oh My Zsh, Powerlevel10k, and zsh-autosuggestions. It also sets the FiraCode NF font in the terminal.
- Install .NET 6 and .NET 7 SDKs. This step includes downloading the tarball files, extracting them into their respective directories, and setting up the necessary environment variables.
