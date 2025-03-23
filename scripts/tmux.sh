#!/bin/env bash

#
git clone -b '3.5' --depth 1 'git@github.com:tmux/tmux.git' ~/tmux
cd ~/tmux
sh autogen.sh
./configure
make && sudo make install

#
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
cp ~/.tmux/.tmux.conf.local ~/
echo "set -g mouse on" | tee --append ~/.tmux.conf.local >/dev/null
