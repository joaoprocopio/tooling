#!/bin/env bash

# studio
## get the release name from the website
MOST_RECENT_ANDROID_STUDIO_RELEASE=$(
  curl -s https://developer.android.com/studio | \
  ## find the linux 64 bit td html element, and catch the next 5 following lines
  grep -A 5 'Linux<br>(64-bit)' | \
  ## extract only the file name
  grep -o 'android-studio-[0-9.]\+-linux' | \
  ## extract the year from the filename
  sed 's/android-studio-\([0-9.]\+\)-linux/\1/'
)

ANDROID_STUDIO_FILENAME="android-studio-$MOST_RECENT_ANDROID_STUDIO_RELEASE-linux.tar.gz"
ANDROID_STUDIO_DOWNLOAD_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/$MOST_RECENT_ANDROID_STUDIO_RELEASE/$ANDROID_STUDIO_FILENAME"

curl -#fSL $ANDROID_STUDIO_DOWNLOAD_URL -o $ANDROID_STUDIO_FILENAME

# extract and move
tar -xvf $ANDROID_STUDIO_FILENAME
sudo mv android-studio /opt/

#
/opt/android-studio/bin/studio.sh

# sdk&jdk
