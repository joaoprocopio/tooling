#!/bin/env sh

#
sudo apt update

#
curl https://pyenv.run | bash

#
echo '
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv > /dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
' | tee --append ~/.zshrc >/dev/null
