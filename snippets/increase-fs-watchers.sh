#!/bin/env bash
# https://stackoverflow.com/a/55763478
# https://www.debian.org/releases/trixie/release-notes/issues.html#etc-sysctl-conf-is-no-longer-honored

# replace the value in the system config
sudo sed -i 's/fs.inotify.max_user_watches = 65536/fs.inotify.max_user_watches=524288/g' /usr/lib/sysctl.d/30-localsearch.conf && \
    sudo sysctl -p

# check that the new value was applied
cat /proc/sys/fs/inotify/max_user_watches
