#!/bin/env bash

#
sudo apt update

#
curl -fsSL https://pyenv.run | bash

#
echo '
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
' | tee --append ~/.zshrc >/dev/null

# opcionalmente adicione essa linha ao seu .zshrc se quiser o pyenv-virtualenv
# eval "$(pyenv virtualenv-init - zsh)"
