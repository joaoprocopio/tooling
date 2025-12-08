#!/bin/env bash

#
ZIG_VERSION="0.14.1"
ZIG_ARCHITECTURE="x86_64-linux"
ZIG_DIRNAME="zig-$ZIG_ARCHITECTURE-$ZIG_VERSION"
ZIG_TARBALL="$ZIG_DIRNAME.tar.xz"
ZIG_TARBALL_URL="https://ziglang.org/download/$ZIG_VERSION/$ZIG_TARBALL"

#
curl "$ZIG_TARBALL_URL" -o "$ZIG_TARBALL"
tar -xvf "$ZIG_TARBALL"
rm "$ZIG_TARBALL"
mv "$ZIG_DIRNAME" "$HOME/zig"

#
echo '
# zig
export PATH="$PATH:$HOME/zig"' | tee --append ~/.zshrc >/dev/null
