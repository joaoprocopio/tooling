#!/bin/env sh

#
sudo apt-get --yes install ninja-build libtool autoconf automake cmake gcc make unzip patch gettext curl git

#
git clone -b stable --depth 1 https://github.com/neovim/neovim ~/neovim

#
cd ~/neovim

#
make CMAKE_BUILD_TYPE=Release
sudo make install
rm -rf build
