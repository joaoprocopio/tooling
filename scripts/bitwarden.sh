#!/bin/env bash

#
sudo apt-get install --yes curl

#
curl -fsSL 'https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb' -o bitwarden.deb

#
sudo dpkg -i bitwarden.deb

#
rm bitwarden.deb
