#!/bin/env bash

#
curl -#fSL 'https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz' -o 'zen.tar.xz'

#
tar -xvf zen.tar.xz

#
rm zen.tar.xz

#
sudo mv zen /opt/

/opt/Postman/app/resources/app/assets

#
cd /opt/zen

#
echo "[Desktop Entry]
Version=1.0
Name=Zen
Comment=Welcome to a calmer internet
GenericName=Web Browser
X-GNOME-FullName=Zen Web Browser
Categories=Network;WebBrowser;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;
Type=Application
Exec=/opt/zen/zen %U -p
Icon=/opt/zen/browser/chrome/icons/default/default128.png
StartupNotify=true
Terminal=false
" | tee ~/.local/share/applications/zen.desktop >/dev/null

