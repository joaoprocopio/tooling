#!/bin/env sh

#
read -p "Type here the email that will be used as your SSH keys:" EMAIL

#
ssh-keygen -t ed25519 -C $EMAIL
