#!/bin/env sh

#
sudo apt update

#
sudo apt install --yes \
  htop \
  tree wget curl ffmpeg net-tools \
  gimp obs-studio qbittorrent vlc \
  gnome-tweaks dconf-editor gnome-shell-extensions \
  ninja-build libtool autoconf automake cmake gcc make unzip patch gettext \
  libfuse2

#
echo "\n# aliases
alias dk='docker'
alias dkc='docker compose'
alias vpn='openvpn3'" | tee --append ~/.zshrc >/dev/null
