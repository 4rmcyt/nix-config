#!/usr/bin/env bash
# Script to dynamically add latest trackers from ngosang/trackerslist to a new torrent

TORRENT_ID="$TR_TORRENT_ID"
TORRENT_NAME="$TR_TORRENT_NAME"

# Check if torrent ID is provided, exit if not (script called incorrectly)
if [[ -z "$TORRENT_ID" ]]; then
    echo "Error: TORRENT_ID not provided. This script must be called by Transmission." | systemd-cat -t add-trackers-err
    exit 1
fi

echo "Attempting to add dynamic trackers for torrent ID: $TORRENT_ID ($TORRENT_NAME)" | systemd-cat -t add-trackers-info

TRACKERS_URL="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt"

# Fetch, remove empty lines and comments (lines starting with #)
# 'curl' and 'grep' will be available in the script's PATH via Nix's 'wrapProgram'.
TRACKERS_RAW=$(curl -s "$TRACKERS_URL" | grep -v '^$' | grep -v '^#')

if [[ -z "$TRACKERS_RAW" ]]; then
    echo "Warning: Failed to fetch tracker list from $TRACKERS_URL or list was empty. No trackers added for $TORRENT_NAME." | systemd-cat -t add-trackers-warn
    exit 0 # Exit gracefully if fetch fails
fi

# Format trackers for transmission-remote: -t "tracker1" -t "tracker2" ...
TRACKERS_ARG=""
while IFS= read -r tracker; do
    if [[ -n "$tracker" ]]; then # Ensure tracker is not empty
        TRACKERS_ARG+="-t \"$tracker\" "
    fi
done <<< "$TRACKERS_RAW"

if [[ -z "$TRACKERS_ARG" ]]; then
    echo "Warning: Processed tracker list was empty. No trackers added for $TORRENT_NAME." | systemd-cat -t add-trackers-warn
    exit 0
fi

# Execute transmission-remote to add trackers.
# 'transmission-remote' will be available in the script's PATH via Nix's 'wrapProgram'.
TRANSMISSION_CMD="transmission-remote $TORRENT_ID --tracker-add $TRACKERS_ARG"

if eval "$TRANSMISSION_CMD"; then
    echo "Successfully added dynamic trackers for torrent ID: $TORRENT_ID ($TORRENT_NAME)." | systemd-cat -t add-trackers-info
else
    echo "Error: Failed to add trackers for torrent ID: $TORRENT_ID ($TORRENT_NAME). Command: ${TRANSMISSION_CMD}" | systemd-cat -t add-trackers-err
fi

exit 0