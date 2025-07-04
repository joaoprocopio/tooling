#!/bin/env bash

#
GHOSTTY_RELEASE='v1.1.3'
git clone -b $GHOSTTY_RELEASE --depth 1 https://github.com/ghostty-org/ghostty ~/ghostty
cd ~/ghostty

#
zig build -Doptimize=ReleaseFast
