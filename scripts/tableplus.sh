#!/bin/env bash

#
sudo apt update

#
# Add TablePlus gpg key
wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/tableplus-archive.gpg > /dev/null

# Add TablePlus repo
echo "deb [arch=amd64] https://deb.tableplus.com/debian/24 tableplus main" | sudo tee /etc/apt/sources.list.d/mullvad.list

# Install
sudo apt update
sudo apt install tableplus