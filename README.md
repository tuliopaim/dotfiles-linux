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

