#!/bin/env zsh

#
sudo apt update

#
sudo apt install --yes apt-transport-https curl

#
mkdir -p /etc/apt/keyrings
curl -sSfL https://packages.openvpn.net/packages-repo.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/openvpn.gpg
sudo chmod a+r /etc/apt/keyrings/openvpn.gpg

echo "deb [signed-by=/etc/apt/keyrings/openvpn.gpg] https://packages.openvpn.net/openvpn3/debian bookworm main" |
  sudo tee /etc/apt/sources.list.d/openvpn3.list >/dev/null

#
sudo apt update
sudo apt install --yes openvpn3
