#!/bin/env bash

: "
  gostaria de não ter que builda o neovim do source,
  mas infelizmente tem algumas libs tipo lazynvim 
  que só funcionam no neovim mais recente
"

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
