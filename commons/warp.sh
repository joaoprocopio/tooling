#!/bin/env bash

#
sudo apt install --yes curl

#
curl -fsSL "https://releases.warp.dev/stable/v0.2024.03.05.08.02.stable_00/warp-terminal_0.2024.03.05.08.02.stable.00_amd64.deb" -o "warp.deb"
sudo dpkg -i warp.deb

#
rm warp.deb

