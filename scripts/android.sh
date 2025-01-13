#!/bin/env bash

# jdk, this should be updated manually
TEMURIM_JDK_RELEASE="jdk-17.0.13%2B11"
TEMURIM_JDK_FILENAME="OpenJDK17U-jdk_x64_linux_hotspot_17.0.13_11.tar.gz"
TEMURIM_JDK_DOWNLOAD_URL="https://github.com/adoptium/temurin17-binaries/releases/download/$TEMURIM_JDK_RELEASE/$TEMURIM_JDK_FILENAME"

#
curl -#fSL $TEMURIM_JDK_DOWNLOAD_URL -o $TEMURIM_JDK_FILENAME

#
JDK_DIRNAME="jdk"
mkdir -p $JDK_DIRNAME
tar -xvf $TEMURIM_JDK_FILENAME --strip-components 1 -C $JDK_DIRNAME
rm $TEMURIM_JDK_FILENAME

#
mv jdk ~/jdk

#
echo '
# temurim jdk
export JAVA_HOME="$HOME/jdk"
export PATH="$PATH:$JAVA_HOME/bin"' | tee --append ~/.zshrc >/dev/null


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
