#!/bin/env sh

#
sudo apt update

# Instale na internet:
# Chrome, Obs, Gimp, Qbittorrent e VLC
sudo apt install --yes \
  htop \
  tree wget curl ffmpeg net-tools \
  gnome-tweaks dconf-editor gnome-shell-extensions \
  ninja-build build-essential libtool autoconf automake cmake gcc make unzip patch gettext \
  libfuse2 libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev curl \
  libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev \
  libgdal-dev libpq-dev libldap2-dev libsasl2-dev

#
echo "\n# aliases
alias dk='docker'
alias dkc='docker compose'
alias vpn='openvpn3'" | tee --append ~/.zshrc >/dev/null
