#!/bin/env bash

# https://ziglang.org/download/index.json
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
mv "$ZIG_DIRNAME" "$HOME/zig"
export PATH="$PATH:$HOME/zig"

# https://ghostty.org/docs/install/build#linux-installation-tips
GHOSTTY_RELEASE='v1.1.3'
git clone -b $GHOSTTY_RELEASE --depth 1 https://github.com/ghostty-org/ghostty ~/ghostty
cd ~/ghostty

#
zig build -p "$HOME/.local" -Doptimize=ReleaseFast
cd ~
rm -rf ~/ghostty
rm -rf ~/zig
sudo mv ~/.local/bin/ghostty /usr/local/bin/