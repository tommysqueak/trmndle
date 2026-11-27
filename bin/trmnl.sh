

get_trmnl_image() {

  if [ -z "$TRMNL_API_KEY" ]; then
    logger "No TRMNL_BASE_URL provided. Add to config.sh."
  fi

  if [ -z "$TRMNL_BASE_URL" ]; then
    logger "No TRMNL_BASE_URL provided. Add to config.sh."
  fi

  local mac_address=$(cat /sys/class/net/wlan0/address | tr a-z A-Z)

  local battery_percent=$(get_kindle_battery)

  # Request the size of the PNG in *pixels* that will martcht the kindles resolution
  local png_dimensions=$(get_kindle_dimensions)
  local png_width=${png_dimensions#* }
  local png_height=${png_dimensions% *}

  local trmnl_response="$(
  curl -sL \
      -H "access-token: $TRMNL_API_KEY" \
      -H "percent-charged: $battery_percent" \
      -H "png-width: $png_width" \
      -H "png-height: $png_height" \
      -H "rssi: 0" \
      -H "ID: $mac_address" \
      -A "trmnl-kindle/0.1.1" \
      "${TRMNL_BASE_URL}/api/display"
  )"

  if [ -z "$trmnl_response" ]; then
    logger "Error: No JSON response."
    # TODO: serve a default broken image?
  else
    # Show part of the JSON in debug (trim if it's too long)
    local short_json="$(echo "$trmnl_response" | cut -c1-60)"
    logger "JSON: ${short_json}..."

    # Parse JSON (naive sed approach)
    local image_url=$(echo "$trmnl_response" | sed -n 's/.*"image_url":"\([^"]*\)".*/\1/p' | sed 's/\\u0026/\&/g' | sed 's/\\//g')

    logger "TRMNL_image_url: ${image_url}"

    local min_refresh_rate=300

    local refresh_rate=$(echo "$trmnl_response" | sed -n 's/.*"refresh_rate":\([^,}]*\).*/\1/p' | tr -d ' "')
    # API range is 60..86400, so 6+ digits is out of range; rejecting it also stops a bogus
    # value from overflowing the comparison below and parking the wake alarm decades away
    case "$refresh_rate" in ''|*[!0-9]*|??????*) refresh_rate=0 ;; esac
    [ "$refresh_rate" -lt "$min_refresh_rate" ] && refresh_rate="$min_refresh_rate"

    # Store for later wake-up scheduling
    echo "$refresh_rate" > refresh_rate

  fi

  echo "$image_url"
}

get_kindle_dimensions() {

  # fetch info about the kindle
  local result=$(eips -i)

  # extract resolution dimensions
  local xres=$(echo "$result" | grep "xres:" | head -1 | awk '{print $2}')
  local yres=$(echo "$result" | grep "yres:" | head -1 | awk '{print $4}')

  echo "$xres $yres"
}

get_kindle_battery() {
  
  local result=$(lipc-get-prop com.lab126.powerd status)

  # Extract just the percentage
  local battery_level=$(echo "$result" | grep "Battery Level:" | cut -d ":" -f2 | tr -d '% ')

  echo "$battery_level"
}
