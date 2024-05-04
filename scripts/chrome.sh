#!/bin/env bash

#
sudo apt-get install --yes curl

#
curl -fsSL 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb' -o 'chrome.deb'

#
sudo dpkg -i chrome.deb

#
rm chrome.deb
