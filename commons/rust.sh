#!/bin/env bash

#
curl https://sh.rustup.rs -sSf | sh

#
echo '\n# rust
. "$HOME/.cargo/env"' | tee --append ~/.zshrc >/dev/null
