#!/usr/bin/env bash

DIR_RPIMONITOR=/etc/rpimonitor
DIR_RPIMONITOR_TEMPLATES="$DIR_RPIMONITOR/template"
# This folder is also configured in the cron task
DIR_RPIMONITOR_WEB_ADDONS=/usr/share/rpimonitor/web/addons
if [ ! -d "$DIR_RPIMONITOR_TEMPLATES" ] || [ ! -f "$DIR_RPIMONITOR/data.conf" ]; then
    echo "$DIR_RPIMONITOR_TEMPLATES is not a directory or $DIR_RPIMONITOR/data.conf is not a file"
    exit -1
fi
if [ ! -d "$DIR_RPIMONITOR_WEB_ADDONS" ]; then
    echo "$DIR_RPIMONITOR_WEB_ADDONS is not a directory"
    exit -1
fi

# Copies and activates the Deluge template
cp deluge.conf $DIR_RPIMONITOR_TEMPLATES
# Adds deluge after network
sed -i -E "s@/network.conf@/network.conf\ninclude=$DIR_RPIMONITOR_TEMPLATES/deluge.conf@" $DIR_RPIMONITOR/data.conf

# Copies the web addon folder
cp -r addon/ $DIR_RPIMONITOR_WEB_ADDONS/deluge/
# Install python requirements (uses sudo to install globally)
sudo pip3 install -r $DIR_RPIMONITOR_WEB_ADDONS/deluge/requirements.txt
# Activates the cron task (assumes Deluge was installed using a "deluge" user)
sudo cp $DIR_RPIMONITOR_WEB_ADDONS/deluge/rpimonitor-deluge.cron /etc/cron.d/rpimonitor-deluge
# Adds deluge in the Addons list on the header
printf "\nweb.addons.3.title=\"Deluge\"\nweb.addons.3.addons=deluge" >> $DIR_RPIMONITOR_TEMPLATES/addons.conf