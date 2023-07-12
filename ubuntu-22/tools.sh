#!/bin/env sh

#
read -p "Type here your personal username: " PERSONAL_USERNAME
read -p "Type here your personal email: " PERSONAL_EMAIL

#
read -p "Type here your work username: " WORK_USERNAME
read -p "Type here your work email: " WORK_EMAIL

#
echo 'Useful software that cant be installed programatically
https://www.google.com/intl/pt-BR/chrome/
https://bitwarden.com/download/
https://code.visualstudio.com/download/
'

#
sudo apt update

#
sudo apt install --yes \
  tmux htop neovim \
  git tree wget curl ffmpeg net-tools \
  gimp obs-studio qbittorrent vlc \
  gnome-tweaks dconf-editor gnome-shell-extensions

#
touch ~/.gitignore
touch ~/.gitconfig

#
echo "**/.vscode/**\n" | tee ~/.gitignore >/dev/null

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
  excludesfile = /home/joaoprocopio/.gitignore
  editor = code --wait" | tee ~/.gitconfig >/dev/null

#
echo "\n# aliases
alias ll='ls -lha'
alias dk='docker'
alias dkc='docker compose'
alias vpn='openvpn3'" | tee --append ~/.zshrc >/dev/null

#
if [ -n "$WORK_EMAIL" ] && [ -n "$WORK_USERNAME" ]; then
  echo "alias clone='git clone --config user.name=\"$WORK_EMAIL\" --config user.email=\"$WORK_USERNAME\"'" | tee --append ~/.zshrc >/dev/null
fi
