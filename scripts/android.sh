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

## adds the desktop entry
echo \
'[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio
Icon=/opt/android-studio/bin/studio.svg
Exec="/opt/android-studio/bin/studio" %f
Comment=The Drive to Develop
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-studio
StartupNotify=true
' | tee ~/.local/share/applications/jetbrains-studio.desktop >/dev/null
## close the opened studio and open from the desktop entry
## go to: Tools > SDK Manager > SDK Tools > Click on Android SDK Command-line Tools (latest) > Apply > Ok > Wait and finish

##
echo '
# android studio
export PATH="$PATH:/opt/android-studio/bin"
export PATH="$PATH:$HOME/Android/Sdk/cmdline-tools/latest/bin"' | tee --append ~/.zshrc >/dev/null
