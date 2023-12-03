#!/bin/env sh

#
sudo apt update

#
sudo apt install --yes git

#
touch ~/.gitignore
touch ~/.gitconfig

#
echo "**/.vscode/**" | tee ~/.gitignore >/dev/null

#
echo "[user]
  name = joaoprocopio
  email = joaovitorcprocopio@gmail.com
[alias]
  st = status
  cm = commit
  co = checkout
  lg = log --graph --decorate --abbrev-commit --all --pretty=format:'%C(auto)%h%Creset %C(cyan)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
[init]
  defaultBranch = main
[core]
  excludesfile = /home/$USER/.gitignore
  editor = code --wait" | tee ~/.gitconfig >/dev/null
