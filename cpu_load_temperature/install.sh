#!/usr/bin/env bash

DIR_RPIMONITOR=/etc/rpimonitor
DIR_RPIMONITOR_TEMPLATES="$DIR_RPIMONITOR/template"
if [ ! -d "$DIR_RPIMONITOR_TEMPLATES" ] || [ ! -f "$DIR_RPIMONITOR/data.conf" ]; then
    echo "$DIR_RPIMONITOR_TEMPLATES is not a directory or $DIR_RPIMONITOR/data.conf is not a file"
    exit -1
fi

# Copies and activates the CPU Load + Temperature template
cp cpu_load_temperature.conf $DIR_RPIMONITOR_TEMPLATES
# Replaces CPU template for the new Load+Temperature
sed -i -E "s@include=$DIR_RPIMONITOR_TEMPLATES/cpu.conf@include=$DIR_RPIMONITOR_TEMPLATES/cpu_load_temperature.conf@" $DIR_RPIMONITOR/data.conf
# Comments out the temperature template
sed -i -E "s@include=$DIR_RPIMONITOR_TEMPLATES/temperature.conf@#include=$DIR_RPIMONITOR_TEMPLATES/temperature.conf@" $DIR_RPIMONITOR/data.conf

# 1st parameter: "notop3" if the script should skip activating the top3 addon
if [ "$1" == "notop3" ]; then
    sed -i -E "s@web.status.1.content.1.line.4=InsertHTML@#web.status.1.content.1.line.4=InsertHTML@" $DIR_RPIMONITOR_TEMPLATES/cpu_load_temperature.conf
else
    # Activates the top3 cron task
    sudo cp /usr/share/rpimonitor/web/addons/top3/top3.cron /etc/cron.d/top3

    # Adds top3 in the Addons list on the header
    printf "\nweb.addons.2.title=\"Top3\"\nweb.addons.2.addons=top3" >> $DIR_RPIMONITOR_TEMPLATES/addons.conf
fi
