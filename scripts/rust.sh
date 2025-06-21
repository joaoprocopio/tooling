#!/bin/env bash

#
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

#
echo '
# rust
. "$HOME/.cargo/env"' | tee --append ~/.zshrc >/dev/null

#
source ~/.zshrc

#
rustup update
rustup component add rust-analyzer

