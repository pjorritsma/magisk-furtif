#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk changes its mount point in the future.
MODDIR=${0%/*}

# Global vars
# Set the path to the Termux binary directory. For Android 14 (or specific versions),
# Termux's binaries are typically located at this path. This path might vary depending on your Android environment.
BINDIR="/data/data/com.termux/files/usr/bin"

# Define the device name for identification purposes in messages
DEVICENAME="Pixel5"

# Set the Discord Webhook URL to send notifications. 
# You would replace this URL with your actual Discord webhook URL to send messages to a Discord channel.
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/xxxxxx/yyyyyyy"

# Option to control whether to send Discord messages or not.
# If set to true, messages will be sent to the Discord webhook; otherwise, they will be skipped.
USEDISCORD=false  # Set to true to enable Discord notifications

# This script will be executed in late_start service mode,
# meaning it runs after most services have been started.

# Wait for the system to complete boot process. 
# This will repeatedly check the "sys.boot_completed" system property, which turns to "1" once boot is done.
while [ "$(getprop sys.boot_completed)" != 1 ]; do
    sleep 1  # Sleep for 1 second before checking again.
done

# Ensure boot has fully completed after getting the boot status
# This introduces a short delay after boot completion to ensure all services are fully initialized.
sleep 5

# Function to send messages to Discord using the webhook URL
send_discord_message() {
    # Check if sending Discord messages is enabled (USEDISCORD=true).
    if [ "$USEDISCORD" = true ]; then
        # Use curl to send a POST request to Discord Webhook with the message content.
        # If the POST fails, it will print a failure message to the terminal.
        "$BINDIR"/curl -X POST -H "Content-Type: application/json" \
        -d "{\"content\": \"$1\"}" "$DISCORD_WEBHOOK_URL" || echo "Failed to send Discord message"
    fi
}

# Function to check the status of the device by checking if specific processes are running.
check_device_status() {
    # Use pidof to check if the processes for Pokémon GO (com.nianticlabs.pokemongo) and FurtiF™ Tools (com.github.furtif.furtifformaps) are running.
    PidPOGO=$(pidof com.nianticlabs.pokemongo)
    PidAPK=$(pidof com.github.furtif.furtifformaps)   
  
    # Check if either of the two processes is missing (i.e., they are not running).
    # If either process is not found (empty PID), the device is considered offline.
    if [[ -z "$PidPOGO" || -z "$PidAPK" ]]; then
        return 1  # Devices are online if both processes are running.
    fi
    return 0  # Devices are offline if either process is not running.
}

# Function to close apps if the device is offline and then restart the necessary application.
close_apps_if_offline_and_start_it() {
    # Force-stop both FurtiF™ Tools and Pokémon GO if they are running (since we assume the device is offline).
    am force-stop com.github.furtif.furtifformaps
    am force-stop com.nianticlabs.pokemongo
    
    # Send a message to Discord that the device is offline and apps were closed.
    send_discord_message "🔴 Alert: $DEVICENAME is offline! Closed --=FurtiF™=-- Tools and Pokémon GO."
    
    # Wait for a short period (5 seconds) before attempting to restart the APK tools.
    sleep 5

    # Call the function to start the APK again.
    start_apk_tools
}

# Function to start the APK (FurtiF™ Tools) and perform actions like login and authorize.
start_apk_tools() {
    # Start the FurtiF™ Tools APK and navigate to its main activity.
    am start -n com.github.furtif.furtifformaps/com.github.furtif.furtifformaps.MainActivity
    
    # Wait for the APK to load completely.
    sleep 5
    
    # Simulate input events (tap, swipe, etc.) to interact with the app UI and perform required actions.
    # These coordinates (e.g., 545, 1350) should be adjusted based on your device's screen and app layout.
    
    input tap 545 1350  # Simulate a tap to log in.
    sleep 10  # Wait for 10 seconds to ensure the login process completes.
    
    input swipe 560 1800 560 450  # Simulate a swipe gesture (possibly to navigate or accept something).
    sleep 3  # Wait for 3 seconds after swipe.
    
    input tap 545 1980  # Tap to authorize or confirm something.
    sleep 10  # Wait for 10 seconds to allow authorization to process.
    
    input tap 545 710  # Tap to recheck services status.
    sleep 1  # Wait for 1 second.
    
    input tap 545 1205  # Tap to start the service (activate or begin some function).
    sleep 1  # Wait for 1 second after starting the service.
    
    # Send a status message to Discord indicating the actions performed.
    send_discord_message "🟢 Status: --=FurtiF™=-- Tools started and actions performed."
}

# Introduce a short delay to allow the system to stabilize after boot before starting the main loop.
sleep 10

# Main loop: Continuously check device status and restart the APK if the device is offline.
while true; do
    # If the device is offline (either POGO or FurtiF™ Tools are not running), close the apps and restart the tools.
    if ! check_device_status; then
        close_apps_if_offline_and_start_it  # Close apps if offline and restart the tools.
        sleep 5  # Wait for 5 seconds before checking status again.
        continue  # Skip the current iteration and start checking again.
    fi
    
    # Wait for 5 minutes (300 seconds) before checking the status again.
    sleep 300
done
