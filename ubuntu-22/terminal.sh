#!/bin/env sh

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
eval "$(starship init zsh)"
' | tee --append ~/.zshrc > /dev/null

#
touch ~/.config/starship.toml

#
echo 'add_newline = false
' | tee ~/.config/starship.toml > /dev/null

#
starship preset plain-text-symbols | tee --append ~/.config/starship.toml > /dev/null
