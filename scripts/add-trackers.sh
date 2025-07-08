#!/bin/sh

TRANSMISSION_REMOTE='/usr/bin/transmission-remote'
AUTH='transmission:hunter2'
TRACKERLIST="/tmp/trackers.list"

trap "rm -f ./$TRACKERLIST" EXIT

wget https://newtrackon.com/api/stable -O "$TRACKERLIST"
wget https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt -O ->> "$TRACKERLIST"

sed -i '/^$/d' $TRACKERLIST
echo "[+] Got $(wc -l $TRACKERLIST) trackers"

# Add trackers to all torrents, just in case™
cat $TRACKERLIST | while read TRACKER; do $TRANSMISSION_REMOTE --auth=$AUTH -t all -td $TRACKER; done
