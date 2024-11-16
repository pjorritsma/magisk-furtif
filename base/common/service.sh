#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk changes its mount point in the future.
MODDIR=${0%/*}

# Global vars
# Set the path to the Termux binary directory. This path might vary depending on the Android version.
# For Android 14 (or specific versions), Termux binaries are typically located at this path.
BINDIR="/data/data/com.termux/files/usr/bin"

# Define the device name to be used in log messages and notifications.
DEVICENAME="Pixel5"

# Set the Discord Webhook URL to send notifications about device status.
# Replace this URL with your actual Discord webhook URL to send messages to a Discord channel.
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/xxxxxx/yyyyyyy"

# Option to control whether to send Discord messages or not.
# If true, messages will be sent to the Discord webhook; otherwise, they will be skipped.
USEDISCORD=false  # Set to true to enable Discord notifications

# URL for Rotom API to check device status.
ROTOMAPI_URL="http://rotom/api/status"

# Option to enable checking the Rotom API status for the device.
USEROTOM=false  # Set to true to enable Rotom API checks

# The script is set to run in the late_start service mode, which ensures it runs after most services are started.

# Wait for the system boot process to complete by checking the "sys.boot_completed" system property.
# The system property will be "1" once boot is fully completed.
while [ "$(getprop sys.boot_completed)" != 1 ]; do
    sleep 1  # Sleep for 1 second before checking again.
done

# Ensure boot has fully completed after checking the boot status by adding a short delay.
sleep 5

# Function to check the device's status using the Rotom API.
rotom_device_status() {
    # Only perform the status check if USEROTOM is enabled (true).
    if [ "$USEROTOM" = true ]; then
        response=$("$BINDIR"/curl -s "$ROTOMAPI_URL")  # Fetch the response from the Rotom API.
        
        # Extract device information based on the device name from the API response.
        device_info=$(echo "$response" | "$BINDIR"/jq -r --arg name "$DEVICENAME" '.devices[] | select(.origin | contains($name))')  
        
        # Check if the device is alive and if free memory is below a certain threshold.
        is_alive=$(echo "$device_info" | "$BINDIR"/jq -r '.isAlive')
        mem_free=$(echo "$device_info" | "$BINDIR"/jq -r '.lastMemory.memFree')   
        
        # If the device is not alive or has insufficient free memory, trigger a Discord alert and reboot.
        if [ "$is_alive" = "false" ] || [ "$mem_free" -lt 200000 ]; then
            send_discord_message "🔴 Alert: Device $DEVICENAME is offline or low on memory. Rebooting now..."
            # Uncomment to enable automatic reboot.
            # reboot
        fi
    fi
}

# Function to send messages to Discord using the webhook URL.
send_discord_message() {
    # Check if sending Discord messages is enabled (USEDISCORD=true).
    if [ "$USEDISCORD" = true ]; then
        # Send a POST request to Discord Webhook with the message content.
        # If the POST request fails, output a failure message to the terminal.
        "$BINDIR"/curl -X POST -H "Content-Type: application/json" \
        -d "{\"content\": \"$1\"}" "$DISCORD_WEBHOOK_URL" || echo "Failed to send Discord message"
    fi
}

# Function to check if specific processes (Pokémon GO and FurtiF™ Tools) are running on the device.
check_device_status() {
    # Use pidof to check if the processes for Pokémon GO and FurtiF™ Tools are running.
    PidPOGO=$(pidof com.nianticlabs.pokemongo)
    PidAPK=$(pidof com.github.furtif.furtifformaps)   
    
    # If either of the processes is not running (empty PID), consider the device offline.
    # If both processes are running, the device is considered online.
    if [[ -z "$PidPOGO" || -z "$PidAPK" ]]; then
        return 1  # Device is offline if either process is missing.
    fi
    return 0  # Device is online if both processes are running.
}

# Function to force-close apps and restart FurtiF™ Tools if the device is offline.
close_apps_if_offline_and_start_it() {
    # Force-stop FurtiF™ Tools and Pokémon GO if they are running (device is offline).
    am force-stop com.github.furtif.furtifformaps
    am force-stop com.nianticlabs.pokemongo
    
    # Notify Discord that the device is offline and apps were closed.
    send_discord_message "🔴 Alert: $DEVICENAME is offline! Closed --=FurtiF™=-- Tools and Pokémon GO."
    
    # Wait for 5 seconds before restarting the APK tools.
    sleep 5

    # Start the APK tools (FurtiF™ Tools).
    start_apk_tools
}

# Function to start the FurtiF™ Tools APK and perform necessary actions.
start_apk_tools() {
    # Start the FurtiF™ Tools APK and launch its main activity.
    am start -n com.github.furtif.furtifformaps/com.github.furtif.furtifformaps.MainActivity
    
    # Wait for the APK to load completely.
    sleep 5
    
    # Simulate user interactions (taps, swipes, etc.) to perform actions in the app.
    # Coordinates are based on the device's screen and app layout and may need adjustments.
    
    input tap 545 1350  # Simulate a tap to log in.
    sleep 10  # Wait for the login process to complete.
    
    input swipe 560 1800 560 450  # Simulate a swipe gesture (possibly to accept or navigate).
    sleep 3  # Wait for 3 seconds after swipe.
    
    input tap 545 1980  # Tap to authorize or confirm an action.
    sleep 10  # Wait for 10 seconds to process the authorization.
    
    input tap 545 710  # Tap to recheck service status.
    sleep 1  # Wait for 1 second.
    
    input tap 545 1205  # Tap to start the service or trigger some function.
    sleep 1  # Wait for 1 second after starting the service.
    
    # Send a status update to Discord indicating that the tools have been started and actions have been performed.
    send_discord_message "🟢 Status: --=FurtiF™=-- Tools started and actions performed."
}

# Introduce a short delay to allow the system to stabilize after boot.
sleep 10

# Main loop to continuously check the device status and restart the APK if necessary.
while true; do
    # If the device is offline (Pokémon GO or FurtiF™ Tools are not running), close apps and restart the tools.
    if ! check_device_status; then
        close_apps_if_offline_and_start_it  # Close apps and restart the tools if offline.
        sleep 5  # Wait for 5 seconds before checking the status again.
        continue  # Skip the current iteration and start checking again.
    fi

    # Wait for 5 minutes (300 seconds) before checking the status again.
    sleep 300
    
    # Perform Rotom API check if USEROTOM is enabled after the 5-minute wait.
    rotom_device_status
done
