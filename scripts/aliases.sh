#!/bin/env bash

#
echo '
# aliases
alias docker-compose="docker compose"
alias k="kubectl"
alias dk="docker"
alias dkc="docker compose"
alias vpn="openvpn3"
alias ll="ls -lha"' | tee --append ~/.zshrc >/dev/null
