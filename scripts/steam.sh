#!/bin/env bash

#
curl -#fSL 'https://cdn.fastly.steamstatic.com/client/installer/steam.deb' -o 'steam.deb'
sudo dpkg -i 'steam.deb'
rm 'steam.deb'
