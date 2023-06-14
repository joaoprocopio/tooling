#!/bin/env sh

#
read -p "Enter your email at your company: " WORK_EMAIL
read -p "Enter your username at your company: " WORK_USERNAME

#
echo 'Useful software that cant be installed programatically
https://www.google.com/intl/pt-BR/chrome/
https://bitwarden.com/download/
https://code.visualstudio.com/download/
'

#
sudo apt install --yes \
  tmux htop neovim \
  git tree wget curl ffmpeg \
  gimp obs-studio qbittorrent vlc \
  gnome-tweaks dconf-editor gnome-shell-extensions

#
cp ../.gitconfig ~/
cp ../.gitignore ~/

#
echo "
# aliases
alias ll='ls -lha'
alias clone='git clone --config user.name='"$WORK_EMAIL"' --config user.email='"$WORK_USERNAME"''
" | tee --append ~/.zshrc > /dev/null
