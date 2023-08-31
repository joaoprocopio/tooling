#!/bin/env sh

#
sudo apt update

#
sudo apt install --yes git zsh curl

#
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
