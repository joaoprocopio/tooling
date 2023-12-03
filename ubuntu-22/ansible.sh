#!/bin/env sh

#
sudo apt update

#
sudo apt install --yes software-properties-common

#
sudo add-apt-repository --yes --update ppa:ansible/ansible

#
sudo apt install --yes ansible
