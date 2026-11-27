#!/bin/sh
#
##############################################################################
#
# Fetch screensaver from a configurable URL.
cd "$(dirname "$0")"
# load configuration
if [ -e "config.sh" ]; then
    source ./config.sh
else
    TMPFILE=/tmp/tmp.onlinescreensaver.png
fi

# load utils
if [ -e "utils.sh" ]; then
    source ./utils.sh
else
    echo "Could not find utils.sh in `pwd`"
    exit
fi

# load trmnl utils
if [ -e "trmnl.sh" ]; then
    source ./trmnl.sh
else
    echo "Could not find trmnl.sh in `pwd`"
    exit
fi

# do nothing if no URL is set
if [ -z $IMAGE_URI ]; then
    logger "No image URL has been set. Please edit config.sh."
    return
fi

# Check WiFi connection status
WIFI_CONNECTION=`lipc-get-prop com.lab126.wifid cmState`
logger "WiFi connection state: $WIFI_CONNECTION"

# Get battery status and build URL with parameters
POWERD_OUTPUT=`/usr/bin/powerd_test -s`
batteryLevel=`echo "$POWERD_OUTPUT" | awk -F: '/Battery Level/ {print substr($2, 1, length($2)-1) + 0}'`
isCharging=`echo "$POWERD_OUTPUT" | awk -F: '/Charging/ {print substr($2,2,length($2))}'`

# Insert Trmnl call here. Trmnl roundtrup - Call Trmnl -> get image url -> continue as usual with that image url 
IMAGE_URI_WITH_PARAMS="$(get_trmnl_image)"

# Capture curl output and exit code for detailed logging
CURL_OUTPUT=$(curl -fsS -m 20 -o "$TMPFILE" "$IMAGE_URI_WITH_PARAMS" 2>&1)
CURL_EXIT_CODE=$?

if [ $CURL_EXIT_CODE -eq 0 ]; then
    mv $TMPFILE $SCREENSAVERFILE
    logger "Screen saver image updated successfully from $IMAGE_URI"
    # refresh screen
    if [ `lipc-get-prop com.lab126.powerd status | grep "Ready" | wc -l` -gt 0 ] || [ `lipc-get-prop com.lab126.powerd status | grep "Screen Saver" | wc -l` -gt 0 ]
    then
        logger "Updating image on screen"
        eips -f -g $SCREENSAVERFILE
    fi
else
    # Log detailed curl failure information
    logger "curl failed with exit code $CURL_EXIT_CODE when downloading $IMAGE_URI_WITH_PARAMS"
    echo "$(date): curl failed with exit code $CURL_EXIT_CODE when downloading $IMAGE_URI_WITH_PARAMS" >> $LOGFILE

    # Log curl error output if available
    if [ -n "$CURL_OUTPUT" ]; then
        echo "$(date): curl error output: $CURL_OUTPUT" >> $LOGFILE
        logger "curl error: $CURL_OUTPUT"
    fi

    # Log common curl exit code meanings
    case $CURL_EXIT_CODE in
        6) echo "$(date): curl error: Could not resolve host" >> $LOGFILE ;;
        7) echo "$(date): curl error: Could not connect to host" >> $LOGFILE ;;
        22) echo "$(date): curl error: HTTP response >= 400" >> $LOGFILE ;;
        28) echo "$(date): curl error: Operation timed out" >> $LOGFILE ;;
        *) echo "$(date): curl error: Unknown exit code $CURL_EXIT_CODE" >> $LOGFILE ;;
    esac
    
    # Clean up temp file if it exists but is incomplete
    if [ -f $TMPFILE ]; then
        rm -f $TMPFILE
        logger "Removed incomplete temporary file $TMPFILE"
    fi

    exit 1
fi
