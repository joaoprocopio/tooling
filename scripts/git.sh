#!/bin/env bash

#
sudo apt update

#
sudo apt install --yes git

#
touch ~/.gitignore
touch ~/.gitconfig

#
echo \
"**/.idea/**
**/.vscode/**
**/.zed/**" | tee ~/.gitignore >/dev/null

#
echo "[user]
  name = joaoprocopio
  email = joaovitorcprocopio@gmail.com
[init]
  defaultBranch = main
[core]
  excludesfile = /home/$USER/.gitignore
  editor = code --wait
  autocrlf = false
[push]
  autoSetupRemote = true" | tee ~/.gitconfig >/dev/null
