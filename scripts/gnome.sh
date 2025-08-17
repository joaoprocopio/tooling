#!/bin/env bash

# TODO: automar a parte de configurar o gnome-tweaks e as extensions
# TODO: NOTA: sobre o appindicator precisa ativar dentro do app de extensões
# TODO: NOTA: precisa ativar o user themes, pra dentro do gnome tweaks trocar o Appearance > Legacy Applications > Adwaita-dark
# TODO: NOTA: colocar no dark mode
# TODO: NOTA: desabilitar application search e indexing
# TODO: NOTA: trocar as fontes padrões
# TODO: NOTA: setar hinting pro full
sudo apt install --yes \
  dconf-editor gnome-tweaks gnome-shell-extensions gnome-shell-extension-appindicator
