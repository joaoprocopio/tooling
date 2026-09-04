#!/bin/env bash

#
sudo apt update

#
sudo apt install --yes tmux

#
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
cp -f ~/.tmux/.tmux.conf.local ~/.tmux.conf.local

# oh-my-tmux ignores anything written after the '# EOF' marker
sed -i "/^# EOF$/i \
set -g mouse on\n\
set -g extended-keys on\n\
set -g extended-keys-format csi-u\n" ~/.tmux.conf.local
