#!/bin/env bash

# you need to install zig in the correct version https://ghostty.org/docs/install/build
# you need to have these dynamic libraries https://ghostty.org/docs/install/build#debian-and-ubuntu

#
sudo apt install --yes minisign

# all variables are prefixed to prevent namespace clashing
GHOSTTY_PUBLIC_KEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
GHOSTTY_VERSION="1.2.3"
GHOSTTY_DIR="ghostty-$GHOSTTY_VERSION"
GHOSTTY_TARBALL_FILE="$GHOSTTY_DIR.tar.gz"

#
curl -#fSL "https://release.files.ghostty.org/$GHOSTTY_VERSION/$GHOSTTY_TARBALL_FILE" -o $GHOSTTY_TARBALL_FILE

# verifies the signature
minisign -Vm $GHOSTTY_TARBALL_FILE -P $GHOSTTY_PUBLIC_KEY

#
tar -xvf $GHOSTTY_TARBALL_FILE
rm $GHOSTTY_TARBALL_FILE

#
if [ ! -d $GHOSTTY_DIR ]; then
    echo "Directory $GHOSTTY_DIR does not exist" >&2
    exit 1
fi

#
pushd $GHOSTTY_DIR
zig build -p "$HOME/.local" -Doptimize=ReleaseFast
popd
rm -rf $GHOSTTY_DIR
