#!/bin/env bash

#
sudo apt-get install --yes curl

#
curl -fsSL 'https://vault.bitwarden.com/download/?app=cli&platform=linux' -o 'bwcli.zip'

#
unzip bwcli.zip

#
rm bwcli.zip

#
chmod 744 bw

#
sudo mv bw /usr/bin/
