#!/bin/env bash

# studio
# get the release name from the website
curl -s https://developer.android.com/studio | \
  # find the linux 64 bit td html element, and catch the next 5 following lines
  grep -A 5 'Linux<br>(64-bit)' | \
  # extract only the file name
  grep -o 'android-studio-[0-9.]\+-linux' | \
  # extract the year from the filename
  sed 's/android-studio-\([0-9.]\+\)-linux/\1/' | \
  read MOST_RECENT_RELEASE_YEAR

DOWNLOAD_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/$MOST_RECENT_RELEASE_YEAR/android-studio-$MOST_RECENT_RELEASE_YEAR-linux.tar.gz"

echo $DOWNLOAD_URL

# sdk&jdk
