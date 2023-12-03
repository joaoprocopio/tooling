#!/bin/env zsh

#
git clone -b stable --depth 1 https://github.com/neovim/neovim ~/neovim
cd ~/neovim
make CMAKE_BUILD_TYPE=Release
sudo make install
rm -rf build
sudo ln -s /usr/local/bin/nvim /usr/local/bin/vim

#
mkdir ~/.config/nvim
curl -o ~/.config/nvim/init.lua https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/init.lua
