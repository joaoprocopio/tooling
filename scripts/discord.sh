#!/bin/env bash

#
sudo apt-get install --yes curl

#
curl -fsSL 'https://discord.com/api/download/stable?platform=linux&format=deb' -o 'discord.deb'

#
sudo dpkg -i discord.deb

#
rm discord.deb
