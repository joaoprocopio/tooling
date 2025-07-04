#!/bin/env bash

#
ZIG_VERSION='0.14.1'
ZIG_ARCHITECTURE='x86_64-linux'

#
ZIG_TARBALL_URL=$(curl -fsSL https://ziglang.org/download/index.json | jq -r ".\"$ZIG_VERSION\".\"$ZIG_ARCHITECTURE\".tarball")

#
curl -#fSL $ZIG_TARBALL_URL -o zig.tar.xz
tar -xvf zig.tar.xz
rm zig.tar.xz

#
mv "zig-$ZIG_ARCHITECTURE-$ZIG_VERSION" ~/zig

#
echo '
# zig
export PATH=$PATH:~/zig
' | tee --append ~/.zshrc >/dev/null

