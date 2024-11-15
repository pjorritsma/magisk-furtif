#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk changes its mount point in the future.
MODDIR=${0%/*}

# This script will be executed in late_start service mode

# wait for boot to complete
while [ "$(getprop sys.boot_completed)" != 1 ]; do
    sleep 1
done

# ensure boot has actually completed
sleep 5

# Uses discord set url and uncomment #send_discord_message "*"
# Set Discord webhook url
#DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/xxxxxxx/yyyyyyyyy"

# Send message to Discord
send_discord_message() {
    curl -X POST -H "Content-Type: application/json" \
    -d "{\"content\": \"$1\"}" "$DISCORD_WEBHOOK_URL" || echo "Failed to send Discord message"
}

# Status device using pidof
check_device_status() {
    PidPOGO=$(pidof com.nianticlabs.pokemongo)
    PidAPK=$(pidof com.github.furtif.furtifformaps)   
    # Check if both processes are running
    if [[ -n $PidPOGO && -n $PidAPK ]]; then
        return 1  # Devices are online
    fi
    return 0  # Devices are offline
}

# Close apps if device offline and start it again
close_apps_if_offline_and_start_it() {
    am force-stop com.github.furtif.furtifformaps
    am force-stop com.nianticlabs.pokemongo
    #send_discord_message "🔴 Alert: The device is offline! Closed --=FurtiF™=-- Tools and Pokémon GO."    
    sleep 5  # Wait before checking status
    start_apk_tools  # Start the APK
}

# Start the APK
start_apk_tools() {
    am start -n com.github.furtif.furtifformaps/com.github.furtif.furtifformaps.MainActivity
    # Ensure the APK load has completed
    sleep 5
    # set your good coords here ...
    # this is coords for pixel5 change this for yours
    input tap 545 1350  # login
    sleep 20
    input swipe 560 1800 560 450  # Swipe
    sleep 10
    input tap 545 1980  # Authorize
    sleep 20
    input tap 545 710   # Recheck Services Status
    sleep 10
    input tap 545 1205  # Start Service
    sleep 10
    #send_discord_message "🟢 Status: --=FurtiF™=-- Tools started and actions performed."
}

# Wait for system to fully load
sleep 10

# Main loop: Check device status & start the APK
while true; do
    if ! check_device_status; then
        close_apps_if_offline_and_start_it  # Close apps if offline and restart
        sleep 5  # Wait before checking status again
        continue  # Skip to the next iteration loop
    fi
    sleep 300  # Check every 5 minutes
done