#!/bin/env bash

#
TOOLBOX_DIRNAME="jetbrains-toolbox-2.5.2.35332"
TOOLBOX_FILENAME="$TOOLBOX_DIRNAME.tar.gz"

#
sudo apt-get install --yes curl

#
# https://www.jetbrains.com/toolbox-app/download/download-thanks.html?platform=linux
curl -fsSL "https://download.jetbrains.com/toolbox/$TOOLBOX_FILENAME" -o "$TOOLBOX_FILENAME"

#
tar -xvf "$TOOLBOX_FILENAME"
rm "$TOOLBOX_FILENAME"

#
cd "$TOOLBOX_DIRNAME"
sudo mv jetbrains-toolbox /usr/bin

#
cd ..
rm -rf "$TOOLBOX_DIRNAME"
