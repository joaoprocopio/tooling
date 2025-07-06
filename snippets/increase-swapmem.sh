#!/bin/env bash

# https://docs.vultr.com/how-to-add-swap-memory-on-debian-12

#
sudo swapoff -a
# if you ram is in between 8GB and 64GB, the swapfile size should be 1.5 time the amount of total RAM
sudo fallocate -l 24G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

#
sudo swapon -s

#
sudo cp /etc/fstab /etc/fstab.bak

# add to `/etc/fstab`
# UUID=abf9a9b8-d717-4e42-9000-2e01935100cc /swapfile swap swap defaults 0 0
