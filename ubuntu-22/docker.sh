#!/bin/env sh

# base installation
#
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

#
sudo apt-get update
sudo apt-get install --yes ca-certificates curl gnupg

#
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

#
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

#
sudo apt-get update
sudo apt-get install --yes \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# post installation
#
sudo groupadd docker

#
sudo usermod -aG docker $USER

#
newgrp docker

#
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
