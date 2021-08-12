#!/usr/bin/env bash

DIR_RPIMONITOR=/etc/rpimonitor
DIR_RPIMONITOR_TEMPLATES="$DIR_RPIMONITOR/template"
if [ ! -d "$DIR_RPIMONITOR_TEMPLATES" ] || [ ! -f "$DIR_RPIMONITOR/data.conf" ]; then
    echo "$DIR_RPIMONITOR_TEMPLATES is not a directory or $DIR_RPIMONITOR/data.conf is not a file"
    exit -1
fi

# 1st parameter: path, defaults to "/hd"
PARAM_HDPATH=$1
DEFAULT_HDPATH=/hd
DEFAULT_SERVICE_REGEX="hd\.mount"
# 2nd parameter: device, defaults to "sda1"
PARAM_DEVICE=$2
DEFAULT_DEVICE=sda1

HDPATH=$DEFAULT_HDPATH
DEVICE=$DEFAULT_DEVICE
if [ "$PARAM_HDPATH" != "" ]; then
    HDPATH=$PARAM_HDPATH
fi
if [ "$PARAM_DEVICE" != "" ]; then
    DEVICE=$PARAM_DEVICE
fi

# Copies and activates the HD template
cp hd.conf $DIR_RPIMONITOR_TEMPLATES
sed -i -E "s@/storage.conf@/storage.conf\ninclude=$DIR_RPIMONITOR_TEMPLATES/hd.conf@" $DIR_RPIMONITOR/data.conf
# Configures the path if it is different than the default
if [ "$HDPATH" != "$DEFAULT_HDPATH" ]; then
    ESCAPED_HDPATH=$(echo "$HDPATH" | sed -E "s@/@\\\\\\\/@g")
    sed -i -E "s@\\\\$DEFAULT_HDPATH@$ESCAPED_HDPATH@" $DIR_RPIMONITOR_TEMPLATES/hd.conf
    sed -i -E "s@$DEFAULT_HDPATH@$HDPATH@" $DIR_RPIMONITOR_TEMPLATES/hd.conf
    # Replaces the service name
    # If the path begins with /, we ignore the first character
    HDPATHFORSERVICE=$HDPATH
    if [ "${HDPATH:0:1}" == "/" ]; then
        HDPATHFORSERVICE="${HDPATH:1}"
    fi
    HDSERVICE=$(echo "${HDPATHFORSERVICE}.mount" | sed -E "s@/@-@g")
    sed -i -E "s@$DEFAULT_SERVICE_REGEX@$HDSERVICE@" $DIR_RPIMONITOR_TEMPLATES/hd.conf
fi

# Configures the device if it is different than the default
if [ "$DEVICE" != "$DEFAULT_DEVICE" ]; then
    sed -i -E "s@$DEFAULT_DEVICE@$DEVICE@" $DIR_RPIMONITOR_TEMPLATES/hd.conf
fi
