#!/bin/env sh

#
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

#
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg

#
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
sudo chmod a+r /etc/apt/trusted.gpg.d/docker.gpg

#
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#
sudo apt-get update
sudo apt-get install --yes \
  docker-ce docker-ce-cli \
  containerd.io docker-buildx-plugin \
  docker-compose-plugin
