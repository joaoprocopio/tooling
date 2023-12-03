#!/bin/env sh

#
curl -sS https://starship.rs/install.sh | sh

#
echo '\n# starship
eval "$(starship init zsh)"' | tee --append ~/.zshrc >/dev/null
