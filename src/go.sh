#!/bin/env bash

#
sudo apt-get update

#
sudo rm -rf /usr/local/go

#
curl -fsSL https://go.dev/dl/go1.22.1.linux-amd64.tar.gz -o go.tar.gz

#
sudo tar -C /usr/local -xf go.tar.gz

#
rm go.tar.gz

#
echo '\n# go
export PATH="$PATH:/usr/local/go/bin"' | tee --append ~/.zshrc >/dev/null
