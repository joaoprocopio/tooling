#!/bin/env bash

#
curl -fsSL https://deno.land/install.sh | sh


#
echo '
# deno
export DENO_INSTALL="/home/joaoprocopio/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"' | tee --append ~/.zshrc >/dev/null

