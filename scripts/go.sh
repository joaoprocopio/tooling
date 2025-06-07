#!/bin/env bash

#
sudo apt-get update

#
sudo rm -rf /usr/local/go

#
curl -fsSL "https://go.dev/dl/go1.24.4.linux-amd64.tar.gz" -o go.tar.gz

#
sudo tar -C /usr/local -xf go.tar.gz

#
rm go.tar.gz

#
echo '
# go
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"' | tee --append ~/.zshrc >/dev/null
