#!/bin/env sh

sudo apt install --yes git zsh curl

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

curl -sS https://starship.rs/install.sh | sh

#
echo '
# starship
eval "$(starship init zsh)"
' >> ~/.zshrc

#
touch ~/.config/starship.toml

#
echo 'add_newline = false
' >> ~/.config/starship.toml

#
starship preset plain-text-symbols >> ~/.config/starship.toml
