#!/bin/env sh

#
curl -sSL https://install.python-poetry.org | python3 -

#
echo '
# poetry
export PATH="/home/joaoprocopio/.local/bin:$PATH"
' | tee --append ~/.zshrc >/dev/null

#
source ~/.zshrc

#
poetry config virtualenvs.create true
poetry config virtualenvs.in-project true
poetry config virtualenvs.prefer-active-python true
