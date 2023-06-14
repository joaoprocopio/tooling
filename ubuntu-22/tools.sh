#!/bin/env sh

# https://www.google.com/intl/pt-BR/chrome/
# https://bitwarden.com/download/
# https://code.visualstudio.com/download

#
sudo apt install --yes \
  tmux htop neovim \
  git tree wget curl ffmpeg \
  gimp obs-studio qbittorrent vlc \
  gnome-tweaks dconf-editor gnome-shell-extensions

#
cp ../.gitconfig ~/
cp ../.gitignore ~/