#!/bin/env sh

#
sudo groupadd docker

#
sudo usermod -aG docker $USER

#
newgrp docker

#
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
