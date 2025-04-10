#!/bin/env bash

#
sudo apt update


# terminal interface tools
sudo apt install --yes \
  htop

# terminal cli tools
sudo apt install --yes \
  rsync tree wget curl ffmpeg net-tools ninja-build build-essential \
  libtool autoconf automake cmake gcc make unzip p7zip-full patch gettext \
  bison re2c byacc pkg-config libgraph-easy-perl # graph-easy, very useful

# gui tools
sudo apt install --yes \
  gimp qbittorrent vlc calibre simple-scan flameshot

# gnome/conf tools
# TODO: automar a parte de configurar o gnome-tweaks e as extensions
sudo apt install --yes \
  dconf-editor gnome-tweaks gnome-shell-extensions gnome-shell-extension-appindicator
# NOTA: sobre o appindicator precisa ativar dentro do app de extensões

# fonts
sudo apt install --yes \
  fonts-jetbrains-mono

# libraries
sudo apt install --yes \
  libfuse2 libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libxcb-xtest0 libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxcb-cursor0 libxmlsec1-dev libffi-dev liblzma-dev \
  ncurses-dev libgdal-dev libpq-dev libldap2-dev libsasl2-dev \
  libasound2-dev libfontconfig-dev libwayland-dev libxkbcommon-x11-dev \
  libzstd-dev libvulkan1 libevent-dev \
  libflac-dev libsdl2-dev
