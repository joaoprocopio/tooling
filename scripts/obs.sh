#!/bin/env bash

#
sudo apt update

#
sudo apt install --yes software-properties-common

#
sudo add-apt-repository --yes --update ppa:obsproject/obs-studio

#
sudo apt install --yes ffmpeg obs-studio
