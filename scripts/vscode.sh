#!/bin/env bash

#
sudo apt-get install --yes curl

#
curl -fsSL 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64' -o 'code.deb'

#
sudo dpkg -i code.deb

#
rm code.deb
