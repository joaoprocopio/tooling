#!/bin/env bash

#
. /etc/os-release

DEBIAN_CODENAME="$VERSION_CODENAME"

case "$DEBIAN_CODENAME" in
    bookworm)
        UBUNTU_CODENAME="jammy"
    ;;
    bullseye)
        UBUNTU_CODENAME="focal"
    ;;
    buster)
        UBUNTU_CODENAME="bionic"
    ;;
    *)
        echo "unknown debian version" >&2
        exit 1
    ;;
esac

#
wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | \
    sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg

#
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | \
    sudo tee /etc/apt/sources.list.d/ansible.list

# it will asks for your input, but in a buggy way, just press enter, you will see a error.
sudo apt update
sudo apt install ansible
