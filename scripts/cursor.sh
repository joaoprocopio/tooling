#!/bin/env bash

# TODO

#
./cursor --appimage-extract "usr/share/icons"
sudo cp -r ./squashfs-root/usr/share/icons/hicolor/* /usr/share/icons/hicolor
sudo gtk-update-icon-cache /usr/share/icons/hicolor

#
./cursor --appimage-extract "cursor.desktop"
sed -i 's/^Icon=co.anysphere.cursor/Icon=cursor/' ./squashfs-root/cursor.desktop
mv ./squashfs-root/cursor.desktop ~/.local/share/applications

#
rm -rf squashfs-root

#
mv ./cursor ~/.local/bin
