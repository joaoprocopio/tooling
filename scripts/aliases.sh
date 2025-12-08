#!/bin/env bash

#
echo '
# aliases
alias docker-compose="docker compose"
alias k="kubectl"
alias dk="docker"
alias dkc="docker compose"
alias ll="ls -lha"' | tee --append ~/.zshrc >/dev/null

echo '
# local bin
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"' | tee --append ~/.zshrc --append ~/.bashrc >/dev/null
