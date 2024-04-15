#!/bin/env bash

#
sudo apt update

#
sudo apt install --yes git zsh curl

#
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#
curl -sS https://starship.rs/install.sh | sh

#
echo '
# starship
eval "$(starship init zsh)"' | tee --append ~/.zshrc >/dev/null

#
starship preset plain-text-symbols -o ~/.config/starship.toml
