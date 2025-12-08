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
[alias]
  st = status
  lg = log --graph --decorate --abbrev-commit --all
[init]
  defaultBranch = main
[core]
  excludesfile = /home/$USER/.gitignore
  editor = zed --wait
[push]
  autoSetupRemote = true" | tee ~/.gitconfig >/dev/null
