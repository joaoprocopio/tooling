#!/bin/env sh

#
read -p "Type here the email that will be used in your SSH keys: " EMAIL

#
ssh-keygen -t ed25519 -C $EMAIL
