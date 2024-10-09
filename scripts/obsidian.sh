#!/bin/env bash

#
sudo apt-get install --yes curl jq

#
curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases | \
    jq '.[0].assets | map(select(.name|endswith(".deb"))) | .[0].browser_download_url' | \
    xargs curl -fsSL -o obsidian.deb

#
sudo dpkg -i obsidian.deb

#
rm obsidian.deb
