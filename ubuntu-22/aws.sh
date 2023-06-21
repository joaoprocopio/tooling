#!/bin/env sh

#
sudo apt install --yes unzip curl

#
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscli.zip"
unzip awscli.zip
sudo ./aws/install

#
rm -rf aws
rm awscli.zip
