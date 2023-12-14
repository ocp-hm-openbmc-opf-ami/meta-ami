#!/bin/sh
# Purpose: Upgrade pre-release BMCs with items needed for media group
# This can be removed when there is no longer a direct upgrade path for BMCs
# which were installed with pre-release images.

# Create groups if not already present
if grep -wq media /etc/group; then
    echo "media group already exists"
else
    echo "media group does not exist, add it"
    groupadd -f media
fi

# Add the root user to the groups
if id -nG root | grep -wq media; then
    echo "root already in media"
else
    echo "root not in group media, add it"
    usermod -a -G media root
fi

# Add all users in the priv-admin group to the
# media group so that it will not break
# exiting setup for any user.
for usr in $(grep '^'priv-admin':.*$' /etc/group | cut -d: -f4 | tr ',' ' ')
do
    # Add the usr to the media group
    if id -nG "$usr" | grep -wq media; then
        echo "$usr already in media"
    else
        echo "$usr not in group media, add it"
        usermod -a -G media "$usr"
    fi
done
