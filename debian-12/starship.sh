#!/bin/env zsh

#
curl -sS https://starship.rs/install.sh | sh

#
echo '\n# starship
eval "$(starship init zsh)"' | tee --append ~/.zshrc >/dev/null

#
starship preset plain-text-symbols -o ~/.config/starship.toml
