#!/bin/env bash

# pre-requisites
sudo apt-get install ninja-build gettext cmake unzip curl

#
git clone -b stable --depth 1 https://github.com/neovim/neovim ~/neovim
cd ~/neovim
make CMAKE_BUILD_TYPE=Release
sudo make install
rm -rf build
sudo ln -s /usr/local/bin/nvim /usr/local/bin/vim

#
git clone --depth 1 https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
