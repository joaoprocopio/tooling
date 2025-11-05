#!/bin/env bash

# jdk, https://adoptium.net/installation/linux/#_deb_installation_on_debian_or_ubuntu
sudo apt install -y wget apt-transport-https gpg

#
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | \
  gpg --dearmor | \
  sudo tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null

#
echo "deb https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/adoptium.list > /dev/null

#
sudo apt update
sudo apt install temurin-17-jdk

#
echo '
# temurim jdk
export JAVA_HOME="/usr/lib/jvm/temurin-17-jdk-amd64"' | tee --append ~/.zshrc >/dev/null

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

## extract and move
tar -xvf $ANDROID_STUDIO_FILENAME
sudo mv android-studio /opt/

## execute the install wizard, follow it step by step
/opt/android-studio/bin/studio.sh

## to add the desktop entry go to: Tools > Create Desktop Entry
## go to: Tools > SDK Manager > SDK Tools > Click on Android SDK Command-line Tools (latest) > Apply > Ok > Wait and finish
echo '
# android studio
export PATH="$PATH:/opt/android-studio/bin"' | tee --append ~/.zshrc >/dev/null

##
echo '
# android studio
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:/opt/android-studio/bin"' | tee --append ~/.zshrc >/dev/null
