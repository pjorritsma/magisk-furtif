#!/system/bin/sh

# =============================================================================
# MagiskFurtif Service Script v3.0 - Complete Module
# =============================================================================

# Initialize logging
LOG_FILE="/sdcard/Download/device_monitor.log"

if [ -f "$LOG_FILE" ]; then
    rm "$LOG_FILE" || {
        echo "Failed to delete existing log file. Exiting."
        exit 1
    }
fi

touch "$LOG_FILE" || {
    echo "Failed to create log file. Exiting."
    exit 1
}
chmod 0666 "$LOG_FILE" 2>/dev/null || true

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Logging functions
log_event() {
    local message="$1"
    local log_level="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$log_level] - $message" >> "$LOG_FILE"
}

# Tool checking
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        if [ -d "/data/data/com.termux/files/usr/bin" ]; then
            log_event "$1 not found. Using Termux path." "WARN"
            echo "/data/data/com.termux/files/usr/bin/$1"
        else
            log_event "$1 not found and Termux is unavailable." "ERROR"
            exit 1
        fi
    else
        echo "$(command -v $1)"
    fi
}

# Runtime calculation
calculate_runtime() {
    local end_time=$(date +%s)
    local elapsed_seconds=$((end_time - START_TIME))
    local hours=$((elapsed_seconds / 900))
    local minutes=$(( (elapsed_seconds % 900) / 60 ))
    echo "${hours}h ${minutes}m"
}

# Device name retrieval
get_device_name() {
    # Try to get device name from FurtifForMaps config
    if [ -f "/data/data/com.github.furtif.furtifformaps/files/config.json" ]; then
        local device_name=$(su -c "cat /data/data/com.github.furtif.furtifformaps/files/config.json" 2>/dev/null | $JQ -r ".RotomDeviceName" 2>/dev/null)
        if [ -n "$device_name" ] && [ "$device_name" != "null" ]; then
            echo "$device_name"
            return 0
        fi
    fi
    
    # Fallback to system properties or default
    local device_name=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    local device_id=$(getprop ro.serialno 2>/dev/null | cut -c1-8 2>/dev/null || echo "00000000")
    echo "${device_name}-${device_id}"
}

# Get device information
get_info() {
    pogo_version="$(dumpsys package com.nianticlabs.pokemongo | grep versionName | cut -d= -f2 | tr -d ' ')"
    mitm_version="$(dumpsys package com.github.furtif.furtifformaps | grep versionName | cut -d= -f2 | tr -d ' ')"
    
    # Get CPU temperature with fallback
    temperature=""
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        temperature="$(awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone0/temp)"
    elif [ -f "/sys/class/thermal/thermal_zone1/temp" ]; then
        temperature="$(awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone1/temp)"
    else
        temperature="N/A"
    fi
    
    module_version=$(awk -F '=' '/^version=/ {print $2}' "/data/adb/modules/playintegrityfix/module.prop" 2>/dev/null || echo "Unknown")
}

# Wait for system to be ready
wait_for_system_ready() {
    MAX_WAIT=30
    start_time=$(date +%s)

    while true; do
        if ip route get 1.1.1.1 &> /dev/null && \
           ping -c1 1.1.1.1 &> /dev/null && \
           [ "$(getprop service.bootanim.exit)" = 1 ]; then
            break
        fi

        if [ $(($(date +%s) - start_time)) -ge $MAX_WAIT ]; then
            break
        fi
        sleep 2
    done

    while [ ! -d "/sdcard/Download" ]; do
        sleep 1
    done
}

# Get local IP address - improved detection
get_local_ip() {
    local ip=""
    
    # Method 1: ip route (most reliable)
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
    if [ -n "$ip" ] && [ "$ip" != "1.1.1.1" ] && [ "$ip" != "eth0" ]; then
        echo "$ip"
        return 0
    fi
    
    # Method 2: ip addr show (parse the output properly)
    ip=$(ip addr show 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | grep "scope global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi
    
    # Method 3: ifconfig fallback
    ip=$(ifconfig 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi
    
    # Fallback
    echo "Unknown"
}

# =============================================================================
# CONFIGURATION FUNCTIONS
# =============================================================================

# Load configuration from JSON file
load_config() {
    CONFIG_FILE="/sdcard/Download/config.json"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_event "Config file not found at $CONFIG_FILE" "ERROR"
        exit 1
    fi

    # Load main configuration
    DISCORD_WEBHOOK_URL=$(get_json_value ".DISCORD_WEBHOOK_URL")
    ROTOM_URL=$(get_json_value ".ROTOM_URL")
    CHECK_INTERVAL=$(get_json_value ".CHECK_INTERVAL")
    MEMORY_THRESHOLD=$(get_json_value ".MEMORY_THRESHOLD")
    ROTOM_AUTH_USER=$(get_json_value ".ROTOM_AUTH_USER")
    ROTOM_AUTH_PASS=$(get_json_value ".ROTOM_AUTH_PASS")
    SLEEP_APP_START=$(get_json_value ".SLEEP_APP_START")

    # Load tap coordinates
    TAB1_X=$(get_json_value ".TAP_COORDINATES[0].x")
    TAB1_Y=$(get_json_value ".TAP_COORDINATES[0].y")
    TAB1_SLEEP=$(get_json_value ".TAP_COORDINATES[0].sleep")

    TAB2_X=$(get_json_value ".TAP_COORDINATES[1].x")
    TAB2_Y=$(get_json_value ".TAP_COORDINATES[1].y")
    TAB2_SLEEP=$(get_json_value ".TAP_COORDINATES[1].sleep")

    TAB3_X=$(get_json_value ".TAP_COORDINATES[2].x")
    TAB3_Y=$(get_json_value ".TAP_COORDINATES[2].y")
    TAB3_SLEEP=$(get_json_value ".TAP_COORDINATES[2].sleep")

    TAB4_X=$(get_json_value ".TAP_COORDINATES[3].x")
    TAB4_Y=$(get_json_value ".TAP_COORDINATES[3].y")
    TAB4_SLEEP=$(get_json_value ".TAP_COORDINATES[3].sleep")

    # Load swipe coordinates
    SWIPE_START_X=$(get_json_value ".SWIPE_COORDINATES.start_x")
    SWIPE_START_Y=$(get_json_value ".SWIPE_COORDINATES.start_y")
    SWIPE_END_X=$(get_json_value ".SWIPE_COORDINATES.end_x")
    SWIPE_END_Y=$(get_json_value ".SWIPE_COORDINATES.end_y")
    SWIPE_DURATION=$(get_json_value ".SWIPE_COORDINATES.duration")
    SWIPE_SLEEP=$(get_json_value ".SWIPE_COORDINATES.sleep")

    # Get whether to use dynamic swipe (default to true if not specified)
    USE_DYNAMIC_SWIPE=$(get_json_value ".USE_DYNAMIC_SWIPE" 2>/dev/null || echo "true")
    
    # Load notification configuration
    ENABLE_STARTUP_NOTIFICATION=$(get_json_value ".NOTIFICATIONS.enable_startup" 2>/dev/null || echo "true")
    ENABLE_STATUS_NOTIFICATIONS=$(get_json_value ".NOTIFICATIONS.enable_status" 2>/dev/null || echo "true")
    ENABLE_ERROR_NOTIFICATIONS=$(get_json_value ".NOTIFICATIONS.enable_errors" 2>/dev/null || echo "true")
    STATUS_NOTIFICATION_INTERVAL=$(get_json_value ".NOTIFICATIONS.status_interval" 2>/dev/null || echo "3600")  # 1 hour default
    NOTIFICATION_RETRY_COUNT=$(get_json_value ".NOTIFICATIONS.retry_count" 2>/dev/null || echo "3")
    
    validate_config
}

# Validate configuration
validate_config() {
    if [ -z "$DISCORD_WEBHOOK_URL" ] || [ -z "$ROTOM_URL" ]; then
        log_event "Missing critical configuration values. Check your JSON file." "ERROR"
        exit 1
    fi
    log_event "Configuration loaded and validated successfully." "INFO"
}

# Get JSON value from config file
get_json_value() {
    local key="$1"
    $JQ -r "$key" "$CONFIG_FILE"
}

# =============================================================================
# NOTIFICATION FUNCTIONS
# =============================================================================

# Notification types and colors
NOTIFICATION_SUCCESS=65280    # Green
NOTIFICATION_WARNING=16776960 # Yellow
NOTIFICATION_ERROR=16711680   # Red
NOTIFICATION_INFO=3447003     # Blue
NOTIFICATION_CRITICAL=10038562 # Dark Red

# Generate enhanced JSON payload for Discord webhook
generate_enhanced_payload() {
    local title="$1"
    local description="$2"
    local color="$3"
    local footer="$4"
    local fields="$5"
    local thumbnail="$6"
    local timestamp="$7"

    if [[ -z "$fields" ]]; then
        fields="[]"
    fi
    
    if [[ -z "$timestamp" ]]; then
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    fi

    $JQ -n \
        --arg title "$title" \
        --arg description "$description" \
        --arg footer "$footer" \
        --argjson fields "$fields" \
        --arg color "$color" \
        --arg thumbnail "$thumbnail" \
        --arg timestamp "$timestamp" \
        '{
            content: "",
            tts: false,
            embeds: [
                {
                    title: $title,
                    description: $description,
                    color: ($color | tonumber),
                    fields: $fields,
                    thumbnail: {
                        url: $thumbnail
                    },
                    timestamp: $timestamp,
                    footer: {
                        text: $footer,
                        icon_url: "https://cdn.discordapp.com/emojis/1234567890123456789.png"
                    },
                    author: {
                        name: "MagiskFurtif Monitor",
                        icon_url: "https://cdn.discordapp.com/emojis/1234567890123456789.png"
                    }
                }
            ],
            components: [],
            actions: {}
        }'
}


# Send Discord message with retry logic
send_discord_message() {
    local json_payload="$1"
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        # Get both response and HTTP status code with error output
        response=$($CURL -s -w "\n%{http_code}" -X POST -k \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
            "$DISCORD_WEBHOOK_URL" 2>&1)
        
        # Split response and HTTP code
        http_code=$(echo "$response" | tail -n1)
        response_body=$(echo "$response" | head -n -1)
        
        # Log response for debugging
        log_event "Discord response: HTTP $http_code, Body: $response_body" "DEBUG"
        
        if [[ "$http_code" -eq 200 ]] || [[ "$http_code" -eq 204 ]]; then
            log_event "Discord message sent successfully" "INFO"
            return 0
        else
            retry_count=$((retry_count + 1))
            log_event "Failed to send Discord message. HTTP status: $http_code, Response: $response_body. Retry $retry_count/$max_retries" "WARN"
            if [ $retry_count -lt $max_retries ]; then
                sleep $((retry_count * 2))  # Exponential backoff
            fi
        fi
    done
    
    log_event "Failed to send Discord message after $max_retries attempts" "ERROR"
    return 1
}

# Send system startup notification
send_startup_notification() {
    get_info  # Refresh device info
    local local_ip=$(get_local_ip)
    local uptime=$(uptime | awk -F'up ' '{print $2}' | awk -F', load' '{print $1}')
    local memory_info=$(free -h | grep "Mem:" | awk '{print $3 "/" $2}' 2>/dev/null || echo "Unknown")
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',' 2>/dev/null || echo "Unknown")
    
    fields=$($JQ -n \
        --arg name1 "🌐 IP Address" --arg value1 "$local_ip" \
        --arg name2 "⏱️ Uptime" --arg value2 "$uptime" \
        --arg name3 "🌡️ CPU Temp" --arg value3 "${temperature}°C" \
        --arg name4 "📱 Device" --arg value4 "$DEVICE_NAME" \
        --arg name5 "💾 Memory" --arg value5 "$memory_info" \
        --arg name6 "📊 Load Avg" --arg value6 "$load_avg" \
        '[{name: $name1, value: $value1, inline: true}, {name: $name2, value: $value2, inline: true}, {name: $name3, value: $value3, inline: true}, {name: $name4, value: $value4, inline: true}, {name: $name5, value: $value5, inline: true}, {name: $name6, value: $value6, inline: true}]'
    )
    
    json_payload=$(generate_enhanced_payload \
        "🚀 MagiskFurtif Service Started" \
        "The monitoring service has successfully initialized and is now running. All systems are operational." \
        "$NOTIFICATION_SUCCESS" \
        "System Status: Online • $(date '+%H:%M:%S')" \
        "$fields" \
        "https://cdn.discordapp.com/emojis/1234567890123456789.png"
    )
    (send_discord_message "$json_payload" &)
}

# Send success notification when apps start successfully
send_success_notification() {
    local local_ip=$(get_local_ip)
    local runtime=$(calculate_runtime)
    local memory_info=$(free -h | grep "Mem:" | awk '{print $3 "/" $2}')
    
    fields=$($JQ -n \
        --arg name1 "📱 Device" --arg value1 "$DEVICE_NAME" \
        --arg name2 "⏱️ Runtime" --arg value2 "$runtime" \
        --arg name3 "🌐 IP Address" --arg value3 "$local_ip" \
        --arg name4 "🌡️ CPU Temp" --arg value4 "${temperature}°C" \
        --arg name5 "💾 Memory" --arg value5 "$memory_info" \
        --arg name6 "📦 Versions" --arg value6 "MapWorld: **v$mitm_version**\nPokémon GO: **v$pogo_version**\nPlay Integrity Fix: **$module_version**" \
        '[{name: $name1, value: $value1, inline: true}, {name: $name2, value: $value2, inline: true}, {name: $name3, value: $value3, inline: true}, {name: $name4, value: $value4, inline: true}, {name: $name5, value: $value5, inline: true}, {name: $name6, value: ($value6 | gsub("\\\\n"; "\n")), inline: false}]'
    )
    
    json_payload=$(generate_enhanced_payload \
        "✅ Apps Successfully Launched" \
        "**--=FurtiF™=-- Tools** and **Pokémon GO** are now running and ready for operation." \
        "$NOTIFICATION_SUCCESS" \
        "Status: All Systems Operational" \
        "$fields" \
        "https://cdn.discordapp.com/emojis/1234567890123456789.png"
    )
    (send_discord_message "$json_payload" &)
}

# Send failure notification when apps fail to start
send_failure_notification() {
    local local_ip=$(get_local_ip)
    local runtime=$(calculate_runtime)
    local last_logs=$(tail -5 /sdcard/Download/device_monitor.log | tr '\n' '; ')
    
    fields=$($JQ -n \
        --arg name1 "📱 Device" --arg value1 "$DEVICE_NAME" \
        --arg name2 "⏱️ Runtime" --arg value2 "$runtime" \
        --arg name3 "🌐 IP Address" --arg value3 "$local_ip" \
        --arg name4 "🔄 Attempts" --arg value4 "$retries" \
        --arg name5 "📋 Last Logs" --arg value5 "$last_logs" \
        '[{name: $name1, value: $value1, inline: true}, {name: $name2, value: $value2, inline: true}, {name: $name3, value: $value3, inline: true}, {name: $name4, value: $value4, inline: true}, {name: $name5, value: $value5, inline: false}]'
    )
    
    json_payload=$(generate_enhanced_payload \
        "❌ Critical: App Launch Failed" \
        "**Apps failed to launch after $retries attempts!** Immediate attention required." \
        "$NOTIFICATION_CRITICAL" \
        "Status: Critical Error" \
        "$fields" \
        "https://cdn.discordapp.com/emojis/1234567890123456789.png"
    )
    (send_discord_message "$json_payload" &)
}

# Send memory warning notification
send_memory_warning_notification() {
    local mem_free="$1"
    local runtime=$(calculate_runtime)
    local local_ip=$(get_local_ip)
    local memory_percent=$((mem_free * 100 / $(grep MemTotal /proc/meminfo | awk '{print $2}')))
    
    fields=$($JQ -n \
        --arg name1 "📱 Device" --arg value1 "$DEVICE_NAME" \
        --arg name2 "⏱️ Runtime" --arg value2 "$runtime" \
        --arg name3 "🌐 IP Address" --arg value3 "$local_ip" \
        --arg name4 "💾 Free Memory" --arg value4 "${mem_free}MB (${memory_percent}%)" \
        --arg name5 "⚠️ Threshold" --arg value5 "${MEMORY_THRESHOLD}MB" \
        '[{name: $name1, value: $value1, inline: true}, {name: $name2, value: $value2, inline: true}, {name: $name3, value: $value3, inline: true}, {name: $name4, value: $value4, inline: true}, {name: $name5, value: $value5, inline: true}]'
    )
    
    json_payload=$(generate_enhanced_payload \
        "⚠️ Low Memory Warning" \
        "Device memory is running low. Apps will be restarted to free up memory." \
        "$NOTIFICATION_WARNING" \
        "Action: Restarting Apps" \
        "$fields" \
        "https://cdn.discordapp.com/emojis/1234567890123456789.png"
    )
    (send_discord_message "$json_payload" &)
}

# Send device not alive notification
send_device_not_alive_notification() {
    local is_alive="$1"
    local runtime=$(calculate_runtime)
    local local_ip=$(get_local_ip)
    
    fields=$($JQ -n \
        --arg name1 "📱 Device" --arg value1 "$DEVICE_NAME" \
        --arg name2 "⏱️ Runtime" --arg value2 "$runtime" \
        --arg name3 "🌐 IP Address" --arg value3 "$local_ip" \
        --arg name4 "🔍 API Status" --arg value4 "is_alive: $is_alive" \
        '[{name: $name1, value: $value1, inline: true}, {name: $name2, value: $value2, inline: true}, {name: $name3, value: $value3, inline: true}, {name: $name4, value: $value4, inline: true}]'
    )
    
    json_payload=$(generate_enhanced_payload \
        "🔴 Device Not Alive" \
        "API check indicates device is not responding. Restarting applications." \
        "$NOTIFICATION_ERROR" \
        "Action: Restarting Apps" \
        "$fields" \
        "https://cdn.discordapp.com/emojis/1234567890123456789.png"
    )
    (send_discord_message "$json_payload" &)
}

# Send PID check failed notification
send_pid_check_failed_notification() {
    local free_mem="$1"
    local runtime=$(calculate_runtime)
    local local_ip=$(get_local_ip)
    local pogo_pid=$(pidof com.nianticlabs.pokemongo || echo "Not running")
    local furtif_pid=$(pidof com.github.furtif.furtifformaps || echo "Not running")
    
    fields=$($JQ -n \
        --arg name1 "📱 Device" --arg value1 "$DEVICE_NAME" \
        --arg name2 "⏱️ Runtime" --arg value2 "$runtime" \
        --arg name3 "🌐 IP Address" --arg value3 "$local_ip" \
        --arg name4 "💾 Free Memory" --arg value4 "${free_mem}MB" \
        --arg name5 "🎮 Pogo PID" --arg value5 "$pogo_pid" \
        --arg name6 "🔧 Furtif PID" --arg value6 "$furtif_pid" \
        '[{name: $name1, value: $value1, inline: true}, {name: $name2, value: $value2, inline: true}, {name: $name3, value: $value3, inline: true}, {name: $name4, value: $value4, inline: true}, {name: $name5, value: $value5, inline: true}, {name: $name6, value: $value6, inline: true}]'
    )
    
    json_payload=$(generate_enhanced_payload \
        "🔄 PID Check Failed" \
        "Process monitoring detected issues. Restarting applications to restore functionality." \
        "$NOTIFICATION_WARNING" \
        "Action: Restarting Apps" \
        "$fields" \
        "https://cdn.discordapp.com/emojis/1234567890123456789.png"
    )
    (send_discord_message "$json_payload" &)
}

# Send periodic status notification
send_status_notification() {
    local local_ip=$(get_local_ip)
    local runtime=$(calculate_runtime)
    local uptime=$(uptime | awk -F'up ' '{print $2}' | awk -F', load' '{print $1}')
    local memory_info=$(free -h | grep "Mem:" | awk '{print $3 "/" $2}')
    local pogo_pid=$(pidof com.nianticlabs.pokemongo || echo "Not running")
    local furtif_pid=$(pidof com.github.furtif.furtifformaps || echo "Not running")
    
    fields=$($JQ -n \
        --arg name1 "📱 Device" --arg value1 "$DEVICE_NAME" \
        --arg name2 "⏱️ Runtime" --arg value2 "$runtime" \
        --arg name3 "🌐 IP Address" --arg value3 "$local_ip" \
        --arg name4 "🌡️ CPU Temp" --arg value4 "${temperature}°C" \
        --arg name5 "💾 Memory" --arg value5 "$memory_info" \
        --arg name6 "🎮 Pogo PID" --arg value6 "$pogo_pid" \
        --arg name7 "🔧 Furtif PID" --arg value7 "$furtif_pid" \
        --arg name8 "⏰ System Uptime" --arg value8 "$uptime" \
        '[{name: $name1, value: $value1, inline: true}, {name: $name2, value: $value2, inline: true}, {name: $name3, value: $value3, inline: true}, {name: $name4, value: $value4, inline: true}, {name: $name5, value: $value5, inline: true}, {name: $name6, value: $value6, inline: true}, {name: $name7, value: $value7, inline: true}, {name: $name8, value: $value8, inline: true}]'
    )
    
    json_payload=$(generate_enhanced_payload \
        "📊 System Status Report" \
        "Regular status update showing current system health and application status." \
        "$NOTIFICATION_INFO" \
        "Status: All Systems Operational" \
        "$fields" \
        "https://cdn.discordapp.com/emojis/1234567890123456789.png"
    )
    (send_discord_message "$json_payload" &)
}

# =============================================================================
# MONITORING FUNCTIONS
# =============================================================================

# Main device status check function
check_device_status() {
    get_info
    runtime=$(calculate_runtime)

    if [ -n "$ROTOM_URL" ]; then
        check_api_status
    else
        log_event "No ROTOM_URL configured. Using PID check fallback." "WARN"
        check_pid_status
    fi
}

# Check device status via API
check_api_status() {
    max_retries=3
    attempt=1
    api_response=""

    fetch_api_data() {
        local curl_cmd="$CURL -s --connect-timeout 7 --max-time 10"
        if [ -n "$ROTOM_AUTH_USER" ] && [ -n "$ROTOM_AUTH_PASS" ]; then
            curl_cmd="$curl_cmd --user $ROTOM_AUTH_USER:$ROTOM_AUTH_PASS"
        fi

        response=$($curl_cmd "$ROTOM_URL")
        http_code=$($curl_cmd -o /dev/null -s -w "%{http_code}" "$ROTOM_URL")

        if [ "$http_code" -ne 200 ] || ! echo "$response" | $JQ empty 2>/dev/null; then
            log_event "API request failed. HTTP $http_code" "ERROR"
            echo ""
            return 1
        fi
        echo "$response"
    }

    while [ $attempt -le $max_retries ]; do
        api_response=$(fetch_api_data)
        if [ -n "$api_response" ]; then
            break
        fi
        log_event "API request attempt $attempt failed, retrying..." "WARN"
        sleep 2
        attempt=$((attempt + 1))
    done

    if [ -n "$api_response" ]; then
        # Log full API response for debugging (first 500 chars)
        api_preview=$(echo "$api_response" | head -c 500)
        log_event "API response preview: $api_preview..." "DEBUG"
        
        device_info=$(echo "$api_response" | $JQ -r --arg name "$DEVICE_NAME" '.devices[] | select(.origin | contains($name))')

        if [ -n "$device_info" ]; then
            # Log found device info
            log_event "Found device info: $device_info" "DEBUG"
            is_alive=$(echo "$device_info" | $JQ -r '.isAlive')
            mem_free=$(echo "$device_info" | $JQ -r '.lastMemory.memFree')
            heartbeat_status=$(echo "$device_info" | $JQ -r '.heartbeatCheckStatus')
            last_message_received=$(echo "$device_info" | $JQ -r '.dateLastMessageReceived')
            
            log_event "API check details: is_alive=$is_alive, mem_free=$mem_free, heartbeat=$heartbeat_status" "DEBUG"
            
            # Check if device is alive
            if [ "$is_alive" = "true" ]; then
                # Check memory threshold
                if [ "$mem_free" -ge "$MEMORY_THRESHOLD" ]; then
                    log_event "API check OK: Device alive and sufficient memory (mem_free: $mem_free)" "INFO"
                    return 0
                else
                    log_event "API check: Device alive but insufficient memory (mem_free: $mem_free, threshold: $MEMORY_THRESHOLD). Restarting apps." "WARN"
                    send_memory_warning_notification "$mem_free"
                    return 1
                fi
            else
                log_event "API check: Device not alive (is_alive: $is_alive, heartbeat: $heartbeat_status). Restarting apps." "WARN"
                send_device_not_alive_notification "$is_alive"
                return 1
            fi
        else
            log_event "API check: Device $DEVICE_NAME not found in API response. Falling back to PID check." "WARN"
        fi
    else
        log_event "API check failed after $max_retries attempts. Falling back to PID check." "WARN"
    fi

    log_event "Using PID check fallback..." "INFO"
    check_pid_status
}

# Check device status via PID
check_pid_status() {
    PidPOGO=$(pidof com.nianticlabs.pokemongo)
    PidAPK=$(pidof com.github.furtif.furtifformaps)

    free_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')

    log_event "PID check details: Pogo=$PidPOGO, Furtif=$PidAPK, free_mem=$free_mem, threshold=$MEMORY_THRESHOLD" "DEBUG"

    # Check individual app status
    if [ -z "$PidPOGO" ]; then
        log_event "PID check: Pokémon GO not running (PID: $PidPOGO)" "WARN"
    fi
    
    if [ -z "$PidAPK" ]; then
        log_event "PID check: FurtifForMaps not running (PID: $PidAPK)" "WARN"
    fi
    
    if [ "$free_mem" -lt "$MEMORY_THRESHOLD" ]; then
        log_event "PID check: Insufficient memory (free_mem: $free_mem < threshold: $MEMORY_THRESHOLD)" "WARN"
    fi

    if [ -n "$PidPOGO" ] && [ -n "$PidAPK" ] && [ "$free_mem" -ge "$MEMORY_THRESHOLD" ]; then
        log_event "PID check OK: Both apps running and sufficient free memory (free_mem: $free_mem)" "INFO"
        return 0
    else
        log_event "PID check FAILED: Apps not running or insufficient memory. Pogo=$PidPOGO, Furtif=$PidAPK, free_mem=$free_mem" "ERROR"
        send_pid_check_failed_notification "$free_mem"
        return 1
    fi
}

# =============================================================================
# AUTOMATION FUNCTIONS
# =============================================================================

# Start APK tools with full automation sequence
start_apk_tools() {
    get_info
    log_event "Starting APK tools for $DEVICE_NAME..." "INFO"
    
    stop_apps
    
    am start -n com.github.furtif.furtifformaps/com.github.furtif.furtifformaps.MainActivity
    sleep "$SLEEP_APP_START"

    perform_automation_sequence
    wait_for_apps_stabilization
}

# Stop all relevant apps
stop_apps() {
    log_event "Stopping FurtifForMaps and Pokémon GO..." "INFO"
    am force-stop com.github.furtif.furtifformaps
    am force-stop com.nianticlabs.pokemongo
    sleep 5
}

# Perform the automation sequence (taps and swipes)
perform_automation_sequence() {
    input tap "$TAB1_X" "$TAB1_Y" && sleep "$TAB1_SLEEP"
    
    if [ "$USE_DYNAMIC_SWIPE" = "true" ]; then
        perform_dynamic_swipe
    else
        input swipe "$SWIPE_START_X" "$SWIPE_START_Y" "$SWIPE_END_X" "$SWIPE_END_Y" "$SWIPE_DURATION" && sleep "$SWIPE_SLEEP"
    fi
    
    input tap "$TAB2_X" "$TAB2_Y" && sleep "$TAB2_SLEEP"
    input tap "$TAB3_X" "$TAB3_Y" && sleep "$TAB3_SLEEP"
    input tap "$TAB4_X" "$TAB4_Y" && sleep "$TAB4_SLEEP"
}

# Perform dynamic swipe based on screen dimensions
perform_dynamic_swipe() {
    # Get screen dimensions
    local screen_size=$(get_screen_size)
    local width=$(echo "$screen_size" | awk '{print $1}')
    local height=$(echo "$screen_size" | awk '{print $2}')
    
    # Calculate swipe coordinates (integer arithmetic)
    local start_x=$((width / 2))
    local start_y=$((height * 7 / 10))
    local end_x=$((width / 2))
    local end_y=1
    
    log_event "Performing dynamic swipe: $start_x,$start_y to $end_x,$end_y (screen: ${width}x${height})" "INFO"
    
    input swipe "$start_x" "$start_y" "$end_x" "$end_y" "$SWIPE_DURATION"
    sleep "$SWIPE_SLEEP"
}

# Get screen size for dynamic calculations
get_screen_size() {
    local size_output=$(wm size)
    local width=1080
    local height=1920
    
    local override_size=$(echo "$size_output" | grep "Override size:" | sed -E 's/.*Override size: ([0-9]+)x([0-9]+).*/\1 \2/')
    if [ -n "$override_size" ]; then
        width=$(echo "$override_size" | awk '{print $1}')
        height=$(echo "$override_size" | awk '{print $2}')
    else
        local physical_size=$(echo "$size_output" | grep "Physical size:" | sed -E 's/.*Physical size: ([0-9]+)x([0-9]+).*/\1 \2/')
        if [ -n "$physical_size" ]; then
            width=$(echo "$physical_size" | awk '{print $1}')
            height=$(echo "$physical_size" | awk '{print $2}')
        fi
    fi
    
    echo "$width $height"
}

# Wait for apps to stabilize and verify they're running
wait_for_apps_stabilization() {
    log_event "Waiting for apps to stabilize..." "DEBUG"
    sleep 30

    retries=3
    success=false
    i=1

    while [ "$i" -le "$retries" ]; do
        PidPOGO=$(pidof com.nianticlabs.pokemongo)
        PidAPK=$(pidof com.github.furtif.furtifformaps)
        
        if [ -n "$PidPOGO" ] && [ -n "$PidAPK" ]; then
            success=true
            break
        else
            log_event "Attempt $i: Apps not running. Retrying full restart..." "WARN"
            sleep 5
            am force-stop com.github.furtif.furtifformaps
            am force-stop com.nianticlabs.pokemongo
            am start -n com.github.furtif.furtifformaps/com.github.furtif.furtifformaps.MainActivity
            sleep "$SLEEP_APP_START"

            input tap "$TAB1_X" "$TAB1_Y" && sleep "$TAB1_SLEEP"
            
            # Use dynamic swipe in retry attempt as well
            if [ "$USE_DYNAMIC_SWIPE" = "true" ]; then
                perform_dynamic_swipe
            else
                input swipe "$SWIPE_START_X" "$SWIPE_START_Y" "$SWIPE_END_X" "$SWIPE_END_Y" "$SWIPE_DURATION" && sleep "$SWIPE_SLEEP"
            fi
            
            input tap "$TAB2_X" "$TAB2_Y" && sleep "$TAB2_SLEEP"
            input tap "$TAB3_X" "$TAB3_Y" && sleep "$TAB3_SLEEP"
            input tap "$TAB4_X" "$TAB4_Y" && sleep "$TAB4_SLEEP"

            log_event "Waiting for apps to stabilize after restart attempt $i..." "DEBUG"
            sleep 20
        fi
        i=$(expr "$i" + 1)
    done

    if [ "$success" = "true" ]; then
        log_event "Apps verified as running. PIDs: Pogo=$PidPOGO, Furtif=$PidAPK" "INFO"
        send_success_notification
    else
        log_event "App launch FAILED. PIDs: Pogo=$PidPOGO, Furtif=$PidAPK" "ERROR"
        send_failure_notification
    fi
}

# =============================================================================
# MAIN SERVICE LOGIC
# =============================================================================

# Initialize
log_event "MagiskFurtif service starting..." "INFO"

# Wait for system to be ready
while [ "$(getprop sys.boot_completed)" != 1 ]; do
    sleep 1
done

# Wait for network and storage
wait_for_system_ready

# Initialize tools first
JQ=$(check_tool jq)
CURL=$(check_tool curl)

# Load configuration
load_config

# Get device name
DEVICE_NAME=$(get_device_name)
if [ -z "$DEVICE_NAME" ]; then
    log_event "Failed to retrieve device name" "ERROR"
    exit 1
fi

log_event "Device name loaded: $DEVICE_NAME" "INFO"

# Set device properties
sleep 30  # Additional startup delay

# Only set ro.adb.secure if it's not already 0
if [ "$(getprop ro.adb.secure)" != "0" ]; then
    setprop ro.adb.secure 0
fi
setprop devicename $DEVICE_NAME

# Discord webhook is ready

# Send startup notification if enabled (only once)
if [ "$ENABLE_STARTUP_NOTIFICATION" = "true" ]; then
    send_startup_notification
    ENABLE_STARTUP_NOTIFICATION="false"  # Prevent multiple startup notifications
fi

# Start initial app launch
start_apk_tools
START_TIME=$(date +%s)

# Initialize status notification timer
LAST_STATUS_NOTIFICATION=$(date +%s)

# Main monitoring loop
while true; do
    sleep "$CHECK_INTERVAL"
    
    # Only set ro.adb.secure if it's not already 0
    if [ "$(getprop ro.adb.secure)" != "0" ]; then
        setprop ro.adb.secure 0
    fi
    
    # Check device status and restart apps if needed
    if ! check_device_status; then
        log_event "Device status check failed. Restarting applications..." "WARN"
        start_apk_tools
    fi
    
    # Send periodic status notification if enabled
    if [ "$ENABLE_STATUS_NOTIFICATIONS" = "true" ]; then
        current_time=$(date +%s)
        time_since_last_status=$((current_time - LAST_STATUS_NOTIFICATION))
        
        if [ $time_since_last_status -ge $STATUS_NOTIFICATION_INTERVAL ]; then
            send_status_notification
            LAST_STATUS_NOTIFICATION=$current_time
        fi
    fi
done