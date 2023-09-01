#!/bin/env sh

#
sudo apt install --yes tmux

#
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
cp ~/.tmux/.tmux.conf.local ~/
echo "set -g mouse on" | tee --append ~/.tmux.conf.local >/dev/null
