#!/bin/env bash

#
curl -fsSL https://fly.io/install.sh | sh

#
echo '\n# fly.io
export FLYCTL_INSTALL="/home/joaoprocopio/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"' | tee --append ~/.zshrc >/dev/null
