#!/bin/env bash

#
curl -fsSL https://dl.pstmn.io/download/latest/linux_64 --output postman.tar.gz

#
tar xzf postman.tar.gz

#
sudo mv Postman /opt/

#
echo "[Desktop Entry]
Categories=Development;
Comment=Supercharge your API workflow
Exec="/opt/Postman/Postman"
Icon=/opt/Postman/app/resources/app/assets/icon.png
Name=Postman
Terminal=false
Type=Application
Version=1.0" | tee ~/.local/share/applications/Postman.desktop >/dev/null

#
rm postman.tar.gz
