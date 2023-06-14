#!/bin/sh

#
sudo snap remove --purge firefox
sudo snap remove --purge snap-store
sudo snap remove --purge snapd-desktop-integration
sudo snap remove --purge gtk-common-themes
sudo snap remove --purge gnome-3-38-2004
sudo snap remove --purge core20
sudo snap remove --purge bare
sudo snap remove --purge snapd
sudo apt remove -y --purge snapd
sudo apt-mark hold snapd

#
echo 'Package: snapd
Pin: release a=*
Pin-Priority: -10' | sudo tee /etc/apt/preferences.d/nosnap.pref

#
sudo apt-mark hold gnome-software-plugin-snap
sudo apt install -y gnome-software
