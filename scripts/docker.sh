#!/bin/env bash

# base installation
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

#
sudo apt-get update
sudo apt-get install --yes ca-certificates curl gnupg

#
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -#fSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

#
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

#
sudo apt-get update
sudo apt-get install --yes \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# post installation
sudo groupadd docker

#
sudo usermod -aG docker $USER

#
newgrp docker

#
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

#
docker run hello-world
