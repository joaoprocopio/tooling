#!/bin/env sh

#
sudo apt-get --yes install ninja-build libtool autoconf automake cmake gcc make unzip patch gettext curl git

#
curl -fsSL https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz --output nvim.tar.gz

#
tar xzf nvim.tar.gz

#
sudo mv nvim-linux64/bin/nvim /usr/bin/

#
rm -rf nvim-linux64
rm nvim.tar.gz
