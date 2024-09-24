#!/bin/env bash

GO_VERSION="1.23.1"

#
sudo apt-get update

#
sudo rm -rf /usr/local/go

#
curl -fsSL "https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz" -o go.tar.gz

#
sudo tar -C /usr/local -xf go.tar.gz

#
rm go.tar.gz

#
echo '
# go
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"' | tee --append ~/.zshrc >/dev/null
