#!/bin/env zsh

: '
  https://www.google.com/chrome
  https://code.visualstudio.com/download
  https://www.videolan.org/vlc
  https://www.qbittorrent.org/download
  https://calibre-ebook.com/download
  '

#
sudo apt update

#
sudo apt install --yes \
  htop gimp \
  tree wget curl ffmpeg net-tools \
  gnome-tweaks dconf-editor gnome-shell-extensions \
  ninja-build build-essential libtool autoconf automake cmake gcc make unzip patch gettext \
  libfuse2 libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxcb-cursor0 \
  libxmlsec1-dev libffi-dev liblzma-dev \
  libgdal-dev libpq-dev libldap2-dev libsasl2-dev \
  libasound2-dev libfontconfig-dev libwayland-dev libxkbcommon-x11-dev libzstd-dev

#
echo "\n# aliases
alias dk='docker'
alias dkc='docker compose'
alias vpn='openvpn3'" | tee --append ~/.zshrc >/dev/null
