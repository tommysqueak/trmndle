#!/bin/sh
#
##############################################################################
#
# Battery-efficient weather screensaver scheduler for Kindle
#
# Features:
#   - updates at the refresh_rate returned by the TRMNL API
#   - uses RTC wakeup to minimize battery drain
#   - only stays awake during actual updates
#   - handles screensaver and ready states efficiently
#
##############################################################################

# change to directory of this script
cd "$(dirname "$0")"

# load configuration
if [ -e "config.sh" ]; then
        source ./config.sh
else
        # set default values
        RTC=0
fi

# load utils
if [ -e "utils.sh" ]; then
	source ./utils.sh
else
	echo "Could not find utils.sh in `pwd`"
	exit 1
fi

###############################################################################


##############################################################################

get_next_update_seconds () {
    local MIN_REFRESH_RATE=300
    local refresh_rate=$(cat refresh_rate 2>/dev/null)
    case "$refresh_rate" in ''|*[!0-9]*|??????*) refresh_rate="" ;; esac
    if [ -z "$refresh_rate" ] || [ "$refresh_rate" -lt "$MIN_REFRESH_RATE" ]; then
        refresh_rate=$MIN_REFRESH_RATE
    fi
    logger "Next update in $refresh_rate seconds (TRMNL refresh_rate)"
    echo "$refresh_rate"
}


##############################################################################

# perform update with timeout protection (Kindle-compatible)
do_update_cycle () {
	logger "Starting update cycle"
	
        # Check initial WiFi status and log it
        WIFI_STATUS=`lipc-get-prop com.lab126.cmd wirelessEnable`
        logger "Initial WiFi status: $WIFI_STATUS"

        # Enable wireless if it is currently off
        if [ 0 -eq "$WIFI_STATUS" ]; then
                logger "WiFi is off, turning it on now"
                lipc-set-prop com.lab126.cmd wirelessEnable 1

                # Give WiFi more time to initialize after turning on
                logger "Waiting 10 seconds for WiFi to initialize..."
                sleep 10
        else
                logger "WiFi was already enabled"
        fi

        # Check WiFi connection status
        WIFI_CONNECTION=`lipc-get-prop com.lab126.wifid cmState`
        logger "WiFi state after groggy toggle: $WIFI_CONNECTION"

	# Check if userstore is available before attempting update
	if ! is_userstore_available; then
		logger "Skipping update - userstore not available (USB mass storage active)"
		return
	fi

	# Run the update in background
	sh ./update.sh &
	UPDATE_PID=$!
	
	# Wait for update to complete with timeout
	TIMEOUT=20  # 20 seconds
	ELAPSED=0
	
	while [ $ELAPSED -lt $TIMEOUT ]; do
		if ! kill -0 $UPDATE_PID 2>/dev/null; then
			# Process has finished
			wait $UPDATE_PID
			UPDATE_RESULT=$?
			if [ $UPDATE_RESULT -eq 0 ]; then
				logger "Update completed successfully in $ELAPSED seconds"
			else
				logger "Update failed with exit code $UPDATE_RESULT after $ELAPSED seconds"
			fi
			return
		fi
		
		sleep 5
		ELAPSED=$(( $ELAPSED + 5 ))
	done
	
	# Timeout reached - kill the update process
	logger "Update timed out after $TIMEOUT seconds, killing process $UPDATE_PID"
	kill $UPDATE_PID 2>/dev/null
	sleep 2
	kill -9 $UPDATE_PID 2>/dev/null  # Force kill if still running
	
	logger "Update cycle finished (timed out)"
}

##############################################################################

# Signal handler for clean shutdown
cleanup_and_exit () {
	logger "Received shutdown signal - performing cleanup"
	flush_temp_logs force
	exit 0
}

# Set up signal traps for clean shutdown
trap cleanup_and_exit INT TERM

# Main event-driven loop
logger "Starting event-driven scheduler - waiting for powerd events"

# Flush any leftover temp logs from previous session
flush_temp_logs force
lipc-wait-event -m com.lab126.powerd goingToScreenSaver,wakeupFromSuspend,readyToSuspend | while read event; do
    logger "Received event: $event"
    
    DEVICE_STATUS=$(lipc-get-prop com.lab126.powerd status)
    logger "Device status: $DEVICE_STATUS"

    case "$event" in
        goingToScreenSaver*)
            logger "Going to screensaver - performing scheduled update"
            do_update_cycle
            ;;
        wakeupFromSuspend*)
            logger "Waking from suspend - waiting 2 seconds for system, then updating"
            sleep 2
            do_update_cycle
            ;;
        readyToSuspend*)
            logger "Ready to suspend - setting RTC wakeup timer"
            NEXT_UPDATE_SECONDS=$(get_next_update_seconds)
            logger "Next update in $NEXT_UPDATE_SECONDS seconds"
            set_rtc_wakeup_relative $NEXT_UPDATE_SECONDS
            ;;
        *)
            logger "Unknown event: $event"
            ;;
    esac
    
    logger "Ensuring WiFi is turned off..."
    lipc-set-prop com.lab126.cmd wirelessEnable 0
done
