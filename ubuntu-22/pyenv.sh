#!/bin/env sh

#
sudo apt update; sudo apt install --yes \
  build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev curl \
  libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev \
  libgdal-dev libpq-dev

#
curl https://pyenv.run | bash

#
echo '
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv > /dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
' | tee --append ~/.zshrc > /dev/null