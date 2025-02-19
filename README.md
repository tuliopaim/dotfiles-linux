## My Dotfiles with Nix

Install nix-darwin stuff

`nix flake update --flake ~/dotfiles/nix-darwin`

`darwin-rebuild switch --flake ~/dotfiles/nix-darwin#macos`

Install brew stuff

`brew update && brew bundle install --cleanup --file ~/dotfiles/brew/Brewfile --no-lock && brew upgrade`
