#!/bin/env bash

#
sudo apt-get install --yes curl

#
curl -fsSL https://code.visualstudio.com/docs/?dv=linux64_deb -o code.deb

#
sudo dpkg -i code.deb

#
rm code.deb
