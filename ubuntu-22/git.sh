#!/bin/env sh

#
read -p "Type here your personal username: " PERSONAL_USERNAME
read -p "Type here your personal email: " PERSONAL_EMAIL

#
read -p "Type here your work username: " WORK_USERNAME
read -p "Type here your work email: " WORK_EMAIL

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
  name = $PERSONAL_USERNAME
  email = $PERSONAL_EMAIL
[alias]
  st = status
  lg = log --graph --decorate --abbrev-commit --all --pretty=format:'%C(auto)%h%Creset %C(cyan)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
[init]
  defaultBranch = main
[core]
  excludesfile = /home/$USER/.gitignore
  editor = code --wait" | tee ~/.gitconfig >/dev/null

#
if [ -n "$WORK_EMAIL" ] && [ -n "$WORK_USERNAME" ]; then
  echo "alias clone='git clone --config user.name=\"$WORK_EMAIL\" --config user.email=\"$WORK_USERNAME\"'" | tee --append ~/.zshrc >/dev/null
fi