#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode

# wait for boot to complete
while [ "$(getprop sys.boot_completed)" != 1 ]; do
    sleep 1
done

# ensure boot has actually completed
sleep 5

# start apk tools
am start -n com.github.furtif.furtifformaps/com.github.furtif.furtifformaps.MainActivity

# ensure apk load has actually completed
sleep 10

# set you good coords here ...
input tap 650 470
sleep 20
input swipe 895 539 895 119 300
sleep 10
input tap 860 600
sleep 20
input tap 640 240
sleep 10
input tap 640 360