#!/bin/env bash

#
sudo apt update

# terminal interface tools
sudo apt install --yes \
  htop

# fontes
sudo apt install --yes \
  fonts-jetbrains-mono fonts-inter

# terminal cli tools
sudo apt install --yes \
  ssh git blueprint-compiler rsync jq tree wget ripgrep curl ffmpeg net-tools ninja-build build-essential mesa-utils \
  libtool autoconf automake cmake gcc make unzip p7zip-full patch gettext \
  bison re2c byacc pkg-config libgraph-easy-perl tree-sitter-cli \
  xsel wl-clipboard linux-perf valgrind

# gui tools
sudo apt install --yes \
  gimp qbittorrent vlc calibre simple-scan

# libraries
sudo apt install --yes \
  libfuse2 libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libxcb-xtest0 libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxml2-utils libxcb-cursor0 libxmlsec1-dev libffi-dev liblzma-dev \
  ncurses-dev libgdal-dev libpq-dev libldap2-dev libsasl2-dev \
  libasound2-dev libfontconfig-dev libwayland-dev libxkbcommon-x11-dev \
  libzstd-dev libvulkan1 libevent-dev \
  libflac-dev libsdl2-dev \
  libgtk-4-dev libadwaita-1-dev libgtk4-layer-shell-dev \
  libapr1-dev libaprutil1-dev libglib2.0-dev libc6-dbg
