#!/bin/env sh

#
sudo apt-get update

#
sudo apt-get install -y gnupg software-properties-common

#
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

#
gpg --no-default-keyring \
  --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  --fingerprint

#
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
  sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

#
sudo apt update

#
sudo apt install terraform
