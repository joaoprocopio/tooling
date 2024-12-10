#!/bin/env bash

#
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'warp-terminal'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'<Ctrl><Alt>T'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'Open Terminal'"
