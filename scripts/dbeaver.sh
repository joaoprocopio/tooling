#!/bin/env bash

#
sudo apt-get install --yes curl

#
curl -#fSL 'https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb' -o 'dbeaver.deb'

#
sudo dpkg -i dbeaver.deb

#
rm dbeaver.deb
