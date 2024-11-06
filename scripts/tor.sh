#!/bin/env bash

#
curl -fsSL 'https://www.torproject.org/dist/torbrowser/14.0.1/tor-browser-linux-x86_64-14.0.1.tar.xz' -o 'tor-browser.tar.xz'

#
tar -xvf tor-browser.tar.xz

#
sudo mv tor-browser /opt/

#
rm tor-browser.tar.xz

#
cd /opt/tor-browser
./start-tor-browser.desktop --register-app
