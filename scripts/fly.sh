#!/bin/env bash

#
curl -#fSL https://fly.io/install.sh | sh

#
echo '
# fly.io
export FLYCTL_INSTALL="/home/joaoprocopio/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"' | tee --append ~/.zshrc >/dev/null
