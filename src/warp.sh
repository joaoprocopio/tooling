#!/bin/env bash

#
sudo apt-get install --yes curl

#
curl -fsSL https://app.warp.dev/download?package=deb -o warp.deb
sudo dpkg -i warp.deb

#
rm warp.deb
