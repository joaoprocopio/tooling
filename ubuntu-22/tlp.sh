#!/bin/env sh

#
sudo add-apt-repository ppa:linrunner/tlp
sudo apt update

#
sudo apt install --yes tlp tlp-rdw

#
sudo systemctl daemon-reload
sudo systemctl mask power-profiles-daemon.service
sudo systemctl enable tlp.service
sudo tlp start

#
tlp-stat -s
