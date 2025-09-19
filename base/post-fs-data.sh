#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode

# Start the MagiskFurtif service in the background
# Wait for system to be ready, then start service
(
    # Wait for system to be fully booted
    until [ "$(getprop sys.boot_completed)" = "1" ]; do
        sleep 1
    done
    
    # Additional wait for network and storage
    sleep 30
    
    # Start the service
    if [ -f "$MODDIR/service.sh" ]; then
        nohup "$MODDIR/service.sh" >/dev/null 2>&1 &
        echo "MagiskFurtif service started in background"
    fi
) &
