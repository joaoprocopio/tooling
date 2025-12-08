#!/bin/env bash

#
sudo apt install --yes minisign

# all variables are prefixed to prevent namespace clashing
GHOSTTY_PUBLIC_KEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
GHOSTTY_VERSION="1.2.3"
GHOSTTY_DIR="ghostty-$GHOSTTY_VERSION"
GHOSTTY_TAR_GZ_FILE="$GHOSTTY_DIR.tar.gz"

#
curl -#fSL "https://release.files.ghostty.org/$GHOSTTY_VERSION/$GHOSTTY_TAR_GZ_FILE" -o $GHOSTTY_TAR_GZ_FILE

# verifies the signature
minisign -Vm $GHOSTTY_TAR_GZ_FILE -P $GHOSTTY_PUBLIC_KEY

#
tar -xvf $GHOSTTY_TAR_GZ_FILE
rm $GHOSTTY_TAR_GZ_FILE

#
if [ ! -d $GHOSTTY_DIR ]; then
    echo "Directory $GHOSTTY_DIR does not exist" >&2
    exit 1
fi

# zig build -p "$HOME/.local" -Doptimize=ReleaseFast
# cd ~
# rm -rf ~/ghostty
# rm -rf ~/zig
# sudo mv ~/.local/bin/ghostty /usr/local/bin/
