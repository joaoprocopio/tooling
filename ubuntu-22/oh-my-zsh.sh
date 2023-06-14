#!/bin/env sh

sudo apt install --yes git zsh

sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

curl -sS https://starship.rs/install.sh | sh

#
echo '
# starship
eval "$(starship init zsh)"
' >> ~/.zshrc