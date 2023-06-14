#!/bin/env sh

#
sudo apt install apt-transport-https

#
curl -fsSL https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub | \
gpg --dearmor | \
sudo tee /etc/apt/trusted.gpg.d/openvpn-repo-pkg-keyring.gpg > /dev/null

#
sudo chmod a+r /etc/apt/trusted.gpg.d/openvpn-repo-pkg-keyring.gpg

#
echo '# OpenVPN 3 Linux client - Ubuntu 22.04 LTS
deb [arch=amd64] https://swupdate.openvpn.net/community/openvpn3/repos jammy main' | \
sudo tee /etc/apt/sources.list.d/openvpn3.list > /dev/null

#
sudo apt update
sudo apt install --yes openvpn3