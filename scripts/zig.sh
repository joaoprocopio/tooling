#!/bin/env bash

# https://ziglang.org/download/index.json

#
ZIG_VERSION="0.13.0"
ZIG_ARCHITECTURE="linux-x86_64"
ZIG_DIRNAME="zig-$ZIG_ARCHITECTURE-$ZIG_VERSION"
ZIG_TARBALL="$ZIG_DIRNAME.tar.xz"
ZIG_TARBALL_URL="https://ziglang.org/download/$ZIG_VERSION/$ZIG_TARBALL"

#
curl "$ZIG_TARBALL_URL" -o "$ZIG_TARBALL"
tar -xvf "$ZIG_TARBALL"
rm "$ZIG_TARBALL"

#
mv "$ZIG_DIRNAME" ~/zig

#
# echo '
# # zig
# export PATH=$PATH:~/zig
# ' | tee --append ~/.zshrc >/dev/null
