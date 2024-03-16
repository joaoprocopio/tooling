#!/bin/env bash

#
export WARP_URL='https://releases.warp.dev/stable/v0.2024.03.12.08.02.stable_01/warp-terminal_0.2024.03.12.08.02.stable.01_amd64.deb'

#
sudo apt install --yes curl

#
curl -fsSL $WARP_URL -o "warp.deb"
sudo dpkg -i warp.deb

#
rm warp.deb

