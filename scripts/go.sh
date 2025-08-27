#!/bin/env bash

#
sudo rm -rf /usr/local/go

#
curl -#fSL "https://go.dev/dl/go1.25.0.linux-amd64.tar.gz" -o go.tar.gz

#
sudo tar -C /usr/local -xf go.tar.gz

#
rm go.tar.gz

#
echo '
# go
export PATH="$PATH:/usr/local/go/bin"' | tee --append ~/.zshrc >/dev/null
