#!/system/bin/sh
# Live monitoring script for MagiskFurtif v3.1
# Shows real-time status of the monitoring service
# Author: Furtif | Editor: PJ0tter

echo "🔍 MagiskFurtif Live Monitor v3.1"
echo "Press Ctrl+C to exit"
echo ""

# Check if colors are supported
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    NC=''
fi

while true; do
    clear
    echo "🔍 MagiskFurtif Live Monitor - $(date)"
    echo "=========================================="
    
    # Service status
    echo -e "\n${BLUE}📱 Service Status:${NC}"
    
    # Check for MagiskFurtif service using multiple methods (with error handling)
    MAGISK_SERVICE_PID=""
    SERVICE_PID=""
    MODULE_SERVICE_PID=""
    EXACT_SERVICE_PID=""
    SH_SERVICE_PID=""
    MAGISK_SERVICE_CHECK=0
    MAGISK_PROCESSES=""
    MAGISK_DAEMON=""
    SHELL_PROCESSES=""
    
    # Skip ps aux since it doesn't work on this device
    
    # Alternative detection methods (top is more reliable on Android)
    PGREP_PID=$(pgrep -f "service.sh" 2>/dev/null | head -1)
    TOP_PID=$(top -n 1 2>/dev/null | grep "service.sh" | awk '{print $1}' | head -1)
    
    # Try to get more detailed info from top (exclude grep processes)
    TOP_SERVICE_INFO=$(top -n 1 2>/dev/null | grep "service.sh" | grep -v "grep" | head -1)
    TOP_EXACT_MATCH=$(top -n 1 2>/dev/null | grep "sh /data/adb/modules/magiskfurtif/service.sh" | grep -v "grep" | head -1)
    
    # Check for Magisk daemon using alternative methods
    MAGISK_DAEMON=$(pgrep -f "magiskd" 2>/dev/null | head -1)
    if [ -z "$MAGISK_DAEMON" ]; then
        MAGISK_DAEMON=$(top -n 1 2>/dev/null | grep "magiskd" | awk '{print $1}' | head -1)
    fi
    
    # Check for Magisk processes using alternative methods
    MAGISK_PROCESSES=$(pgrep -f "magisk" 2>/dev/null | tr '\n' ' ')
    if [ -z "$MAGISK_PROCESSES" ]; then
        MAGISK_PROCESSES=$(top -n 1 2>/dev/null | grep "magisk" | awk '{print $1}' | tr '\n' ' ')
    fi
    MAGISK_SERVICE_CHECK=$(echo "$MAGISK_PROCESSES" | wc -w)
    
    # Prioritize top detection since it works better on Android
    if [ -n "$TOP_EXACT_MATCH" ]; then
        TOP_EXACT_PID=$(echo "$TOP_EXACT_MATCH" | awk '{print $1}')
        echo -e "   ${GREEN}✅ MagiskFurtif Service: Running (PID: $TOP_EXACT_PID) - TOP exact match!${NC}"
        echo -e "   ${GREEN}   Command: $(echo "$TOP_EXACT_MATCH" | awk '{for(i=8;i<=NF;i++) printf "%s ", $i; print ""}')${NC}"
    elif [ -n "$TOP_SERVICE_INFO" ]; then
        TOP_SERVICE_PID=$(echo "$TOP_SERVICE_INFO" | awk '{print $1}')
        echo -e "   ${GREEN}✅ MagiskFurtif Service: Running (PID: $TOP_SERVICE_PID) - TOP detected${NC}"
        echo -e "   ${GREEN}   Command: $(echo "$TOP_SERVICE_INFO" | awk '{for(i=8;i<=NF;i++) printf "%s ", $i; print ""}')${NC}"
    elif [ -n "$EXACT_SERVICE_PID" ]; then
        echo -e "   ${GREEN}✅ MagiskFurtif Service: Running (PID: $EXACT_SERVICE_PID) - ps exact match${NC}"
    elif [ -n "$SH_SERVICE_PID" ]; then
        echo -e "   ${GREEN}✅ MagiskFurtif Service: Running (PID: $SH_SERVICE_PID) - ps sh process${NC}"
    elif [ -n "$MAGISK_SERVICE_PID" ]; then
        echo -e "   ${GREEN}✅ MagiskFurtif Service: Running (PID: $MAGISK_SERVICE_PID) - ps detected${NC}"
    elif [ -n "$MODULE_SERVICE_PID" ]; then
        echo -e "   ${GREEN}✅ Module Service: Running (PID: $MODULE_SERVICE_PID) - ps module${NC}"
    elif [ -n "$SERVICE_PID" ]; then
        echo -e "   ${YELLOW}⚠️  Generic service.sh: Running (PID: $SERVICE_PID) - ps generic${NC}"
    elif [ -n "$PGREP_PID" ]; then
        echo -e "   ${YELLOW}⚠️  Service found via pgrep (PID: $PGREP_PID)${NC}"
    elif [ -n "$TOP_PID" ]; then
        echo -e "   ${YELLOW}⚠️  Service found via top (PID: $TOP_PID)${NC}"
    elif [ -n "$SHELL_PROCESSES" ]; then
        echo -e "   ${YELLOW}⚠️  Shell service processes found (PIDs: $SHELL_PROCESSES)${NC}"
    else
        echo -e "   ${RED}❌ No service.sh processes found${NC}"
    fi
    
    # Magisk specific status
    if [ -n "$MAGISK_DAEMON" ]; then
        echo -e "   ${GREEN}✅ Magisk daemon running (PID: $MAGISK_DAEMON)${NC}"
    else
        echo -e "   ${RED}❌ Magisk daemon not found${NC}"
    fi
    
    if [ "$MAGISK_SERVICE_CHECK" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Magisk processes detected: $MAGISK_SERVICE_CHECK${NC}"
        if [ -n "$MAGISK_PROCESSES" ]; then
            echo -e "   ${GREEN}   Magisk PIDs: $MAGISK_PROCESSES${NC}"
        fi
    else
        echo -e "   ${RED}❌ No Magisk processes found${NC}"
    fi
    
    # Service is running, no need to check module directory
    
    # Check for Magisk service processes (already calculated above)
    if [ "$MAGISK_SERVICE_CHECK" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Magisk processes: $MAGISK_SERVICE_CHECK running${NC}"
        if [ -n "$MAGISK_PROCESSES" ]; then
            echo -e "   ${GREEN}   Magisk PIDs: $MAGISK_PROCESSES${NC}"
        fi
    else
        echo -e "   ${RED}❌ No Magisk processes found${NC}"
    fi
    
    # Check if service is actually running by looking at the log
    if [ -f "/sdcard/Download/device_monitor.log" ]; then
        LAST_LOG_ENTRY=$(tail -1 /sdcard/Download/device_monitor.log 2>/dev/null)
        if echo "$LAST_LOG_ENTRY" | grep -q "MagiskFurtif service"; then
            echo -e "   ${GREEN}✅ Service activity detected in logs${NC}"
        else
            echo -e "   ${YELLOW}⚠️  No recent service activity in logs${NC}"
        fi
        
        # Check log file age
        LOG_AGE=$(stat -c %Y /sdcard/Download/device_monitor.log 2>/dev/null || echo "0")
        CURRENT_TIME=$(date +%s)
        LOG_DIFF=$((CURRENT_TIME - LOG_AGE))
        if [ $LOG_DIFF -lt 300 ]; then  # Less than 5 minutes
            echo -e "   ${GREEN}✅ Log file is recent (${LOG_DIFF}s ago)${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Log file is old (${LOG_DIFF}s ago)${NC}"
        fi
    fi
    
    # Check for Magisk service context
    if [ -f "/data/adb/modules/magiskfurtif/service.sh" ]; then
        # Check if service.sh is being executed by Magisk
        MAGISK_EXEC_CHECK=$(ps aux | grep -E "(magisk.*service|service.*magisk)" | grep -v grep | wc -l)
        if [ "$MAGISK_EXEC_CHECK" -gt 0 ]; then
            echo -e "   ${GREEN}✅ Magisk service execution detected${NC}"
        else
            echo -e "   ${YELLOW}⚠️  No Magisk service execution detected${NC}"
        fi
    fi
    
    # Application status
    echo -e "\n${BLUE}🎮 Application Status:${NC}"
    POGO_PID=$(pidof com.nianticlabs.pokemongo)
    FURTIF_PID=$(pidof com.github.furtif.furtifformaps)
    
    if [ -n "$POGO_PID" ]; then
        echo -e "   ${GREEN}✅ Pokémon GO: Running (PID: $POGO_PID)${NC}"
    else
        echo -e "   ${RED}❌ Pokémon GO: Not running${NC}"
    fi
    
    if [ -n "$FURTIF_PID" ]; then
        echo -e "   ${GREEN}✅ FurtifForMaps: Running (PID: $FURTIF_PID)${NC}"
    else
        echo -e "   ${RED}❌ FurtifForMaps: Not running${NC}"
    fi
    
    # Memory status
    echo -e "\n${BLUE}💾 Memory Status:${NC}"
    FREE_MEM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEM_PERCENT=$((FREE_MEM * 100 / TOTAL_MEM))
    
    if [ $MEM_PERCENT -gt 20 ]; then
        echo -e "   ${GREEN}✅ Free memory: ${FREE_MEM}KB (${MEM_PERCENT}%)${NC}"
    elif [ $MEM_PERCENT -gt 10 ]; then
        echo -e "   ${YELLOW}⚠️  Free memory: ${FREE_MEM}KB (${MEM_PERCENT}%)${NC}"
    else
        echo -e "   ${RED}❌ Free memory: ${FREE_MEM}KB (${MEM_PERCENT}%)${NC}"
    fi
    
    # Device info
    echo -e "\n${BLUE}📱 Device Info:${NC}"
    DEVICE_NAME=""
    
    # Try to get device name from FurtifForMaps config
    if [ -f "/data/data/com.github.furtif.furtifformaps/files/config.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            # Get device name with proper error handling and prevent command interpretation
            DEVICE_NAME=$(su -c "cat /data/data/com.github.furtif.furtifformaps/files/config.json" 2>/dev/null | jq -r '.RotomDeviceName' 2>/dev/null | head -1)
            # Check if the result is valid (not null, not empty, and not a command)
            if [ -z "$DEVICE_NAME" ] || [ "$DEVICE_NAME" = "null" ] || [ "$(echo "$DEVICE_NAME" | wc -c)" -gt 50 ]; then
                DEVICE_NAME=""
            fi
        fi
    fi
    
    # Fallback to system properties if no device name found
    if [ -z "$DEVICE_NAME" ] || [ "$DEVICE_NAME" = "null" ]; then
        device_model=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
        device_id=$(getprop ro.serialno 2>/dev/null | cut -c1-8 2>/dev/null || echo "00000000")
        DEVICE_NAME="${device_model}-${device_id}"
    fi
    
    echo -e "   Device: $DEVICE_NAME"
    
    # System info
    echo -e "\n${BLUE}🖥️  System Info:${NC}"
    CPU_TEMP=""
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        CPU_TEMP=$(awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone0/temp)
    elif [ -f "/sys/class/thermal/thermal_zone1/temp" ]; then
        CPU_TEMP=$(awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone1/temp)
    else
        CPU_TEMP="N/A"
    fi
    echo -e "   CPU Temp: ${CPU_TEMP}°C"
    
    # Network info - improved IP detection
    LOCAL_IP=""
    
    # Method 1: ip route (most reliable)
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
    if [ -n "$LOCAL_IP" ] && [ "$LOCAL_IP" != "1.1.1.1" ] && [ "$LOCAL_IP" != "eth0" ]; then
        echo -e "   Local IP: $LOCAL_IP (via ip route)"
    else
        # Method 2: ip addr show (parse the output properly)
        LOCAL_IP=$(ip addr show 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | grep "scope global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
        if [ -n "$LOCAL_IP" ]; then
            echo -e "   Local IP: $LOCAL_IP (via ip addr)"
        else
            # Method 3: ifconfig fallback
            LOCAL_IP=$(ifconfig 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
            if [ -n "$LOCAL_IP" ]; then
                echo -e "   Local IP: $LOCAL_IP (via ifconfig)"
            else
                echo -e "   Local IP: Unknown"
            fi
        fi
    fi
    
    # Recent logs
    echo -e "\n${BLUE}📋 Recent Logs:${NC}"
    if [ -f "/sdcard/Download/device_monitor.log" ]; then
        tail -3 /sdcard/Download/device_monitor.log | sed 's/^/   /'
    else
        echo -e "   ${YELLOW}⚠️  No log file found${NC}"
    fi
    
    # Service control options
    echo -e "\n${BLUE}🔧 Service Control:${NC}"
    if [ -z "$PGREP_PID" ] && [ -z "$TOP_PID" ] && [ -z "$TOP_SERVICE_INFO" ] && [ -z "$TOP_EXACT_MATCH" ]; then
        echo -e "   ${YELLOW}💡 Service not running. To start manually:${NC}"
        echo -e "   ${YELLOW}   adb shell 'nohup /data/adb/modules/magiskfurtif/service.sh &'${NC}"
        echo -e "   ${YELLOW}   Or check if auto-start is working after reboot${NC}"
        
        # Debug information
        echo -e "\n${BLUE}🔍 Debug Info:${NC}"
        echo -e "   ${YELLOW}All detection methods failed. Try these commands:${NC}"
        echo -e "   ${YELLOW}   adb shell 'top -n 1 | grep service'${NC}"
        echo -e "   ${YELLOW}   adb shell 'top -n 1 | grep magiskfurtif'${NC}"
        echo -e "   ${YELLOW}   adb shell 'pgrep -f service.sh'${NC}"
        echo -e "   ${YELLOW}   adb shell 'pgrep -f magisk'${NC}"
        echo -e "   ${YELLOW}   adb shell 'ls -la /data/adb/modules/magiskfurtif/'${NC}"
        echo -e "   ${YELLOW}   adb shell 'magisk --list'${NC}"
        echo -e "   ${YELLOW}   adb shell 'cat /sdcard/Download/device_monitor.log | tail -10'${NC}"
        
        # Show current top output for debugging
        echo -e "\n${BLUE}📊 Current TOP Output:${NC}"
        TOP_OUTPUT=$(top -n 1 2>/dev/null | grep -E "(service|magisk)" | head -5)
        if [ -n "$TOP_OUTPUT" ]; then
            echo "$TOP_OUTPUT" | sed 's/^/   /'
        else
            echo -e "   ${YELLOW}No service/magisk processes found in top${NC}"
        fi
    else
        echo -e "   ${GREEN}✅ Service is running properly${NC}"
    fi
    
    echo -e "\n${BLUE}⏰ Refreshing in 5 seconds... (Press Ctrl+C to exit)${NC}"
    sleep 5
done
