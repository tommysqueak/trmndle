

get_trmnl_image() {

  if [ -z "$TRMNL_API_KEY" ]; then
    logger "No TRMNL_BASE_URL provided. Add to config.sh."
  fi

  if [ -z "$TRMNL_BASE_URL" ]; then
    logger "No TRMNL_BASE_URL provided. Add to config.sh."
  fi

  local MAC_ADDRESS=$(cat /sys/class/net/wlan0/address | tr '[:lower:]' '[:upper:]')
  local BATTERY_VOLTAGE=$(get_kindle_battery)

  # Size of the PNG in *pixels*
  local PNG_WIDTH=$(get_kindle_height)
  local PNG_HEIGHT=$(get_kindle_width)

  local RESPONSE="$(
  curl -s \
      -H "access-token: $TRMNL_API_KEY" \
      -H "battery-voltage: $BATTERY_VOLTAGE" \
      -H "png-width: $PNG_WIDTH" \
      -H "png-height: $PNG_HEIGHT" \
      -H "rssi: 0" \
      -H "ID: $MAC_ADDRESS" \
      -A "trmnl-display/0.1.1" \
      "${TRMNL_BASE_URL}/api/display"
  )"

  if [ -z "$RESPONSE" ]; then
    logger "Error: No JSON response."
    # TODO: serve a default broken image?
  else
    # Show part of the JSON in debug (trim if it's too long)
    local SHORT_JSON="$(echo "$RESPONSE" | cut -c1-60)"
    logger "JSON: ${SHORT_JSON}..."

    # Parse JSON (naive sed approach)
    local IMAGE_URL=$(echo "$RESPONSE" | sed -n 's/.*"image_url":"\([^"]*\)".*/\1/p' | sed 's/\\u0026/\&/g' | sed 's/\\//g')
    logger "TRMNL_IMAGE_URL: ${IMAGE_URL}"

    local REFRESH_RATE=$(echo "$RESPONSE" | sed -n 's/.*"refresh_rate":\([^,}]*\).*/\1/p')
    [ -z "$REFRESH_RATE" ] && REFRESH_RATE="60"
    # TOOD: is it possible to override the configured schedule and use Trmnls? see scheduler.sh

  fi

  echo "$IMAGE_URL"
}

get_kindle_width() {
  # Run the command and capture its output
  local result=$(eips -i)

  # Extract xres using grep and awk
  local xres=$(echo "$result" | grep "xres:" | head -1 | awk '{print $2}')

  # Return just the width value
  echo "$xres"
}

get_kindle_height() {
  # Run the command and capture its output
  local result=$(eips -i)

  # Extract yres using grep and awk
  local yres=$(echo "$result" | grep "yres:" | head -1 | awk '{print $4}')

  # Return just the height value
  echo "$yres"
}

get_kindle_battery() {
  # Run the command and capture its output
  local result=$(lipc-get-prop com.lab126.powerd status)

  # Extract the battery level using grep and cut
  # Find the line with "Battery Level", extract just the percentage number
  local battery_level=$(echo "$result" | grep "Battery Level:" | cut -d ":" -f2 | tr -d '% ')

  # Return just the number
  echo "$battery_level"
}
