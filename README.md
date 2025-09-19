# Device Monitor Service for --=FurtiF™=-- Tools

A robust monitoring script for Android devices running --=FurtiF™=-- Tools.  
**Version 3.2** | Enhanced Monitoring with Modular Architecture

---

## 📋 Prerequisites

### 1. **Required Tools**  
- `jq` and `curl` must be installed on the device.  
  - **Pre-installed on PoGoROM devices** (no action needed):  
    - ✅ **TX9s**  
    - ✅ **X96mini**
    - ✅ **A95XF1** 
    - ✅ **H96max V11 RK3318 (Android 11)**  
    These devices already include the tools via the [ClawOfDead PoGoROM](https://github.com/ClawOfDead/ATVRoms/releases) and [Andis PoGoROM](https://github.com/andi2022/PoGoRom/releases) repository.  

  - **For other devices**: Install via Termux (see below).
    - ✅ **H96max v13 RK3528 (Android 13)**
    - ✅ **Rasberry Pi 4/5 (Android 13)**

---

## 📥 Installation PoGoROM Devices

### Method 1: Magisk Manager  
1. Download the module ZIP:  
   `MagiskFurtif-f3ger-3.2.zip`  
2. Open **Magisk Manager** → **Modules** → **Install from storage**.  
3. Select the ZIP and reboot.  

### Method 2: PixelFlasher (Advanced)  
1. Load the ZIP in PixelFlasher.  
2. Flash the module and reboot.  

---

## ⚙️ Configuration

1. **Edit `config.json`**:  
   - Update `DISCORD_WEBHOOK_URL`, `ROTOM_URL`, etc.  
   - Use `config.example.json` as a template.  
   - Configure notification settings in the `NOTIFICATIONS` section

2. **Place `config.json`**:  
   Copy to:
   ```
   /sdcard/Download/
   ```

### 📱 Notification Configuration

The module now supports enhanced Discord notifications with the following options:

```json
"NOTIFICATIONS": {
  "enable_startup": true,        // Send notification when service starts
  "enable_status": true,         // Send periodic status reports
  "enable_errors": true,         // Send error notifications
  "status_interval": 3600,       // Status report interval (seconds)
  "retry_count": 3               // Discord API retry attempts
}
```

**Notification Types:**
- 🚀 **Startup**: Service initialization
- ✅ **Success**: Apps launched successfully  
- ⚠️ **Warning**: Memory low, PID issues
- ❌ **Error**: Critical failures
- 📊 **Status**: Periodic health reports

---

## 🆕 Version 3.2 Changelog

### ✨ New Features
- **Improved Workflow Files**: Enhanced GitHub Actions workflows for better CI/CD
- **Better Service Detection**: Enhanced process detection using top and pgrep methods
- **Robust IP Detection**: Improved IP address detection with multiple fallback methods
- **Enhanced Monitor Script**: Better live monitoring with improved error handling

### 🔧 Improvements
- **Workflow Reliability**: Fixed workflow files for consistent builds and releases
- **Service Monitoring**: Better detection of MagiskFurtif service processes
- **IP Address Accuracy**: Fixed "eth0" display issue, now shows actual IP addresses
- **Error Handling**: Improved error handling in both service.sh and monitor_live.sh

### 🐛 Bug Fixes
- **Workflow Issues**: Fixed GitHub Actions workflow files for proper module building
- **Service Detection**: Fixed service process detection on Android devices
- **IP Display**: Fixed IP address showing as "eth0" instead of actual IP
- **Device Name**: Fixed device name detection from FurtifForMaps config

---

## 🆕 Version 3.0 Changelog

### ✨ New Features
- **Modular Architecture**: Split into separate modules for better maintainability
- **Enhanced Discord Notifications**: Rich embeds with thumbnails, timestamps, and detailed information
- **Improved Monitoring**: Better error detection and automatic app restart functionality
- **Configurable Notifications**: Enable/disable different notification types
- **Detailed Logging**: Enhanced debugging and troubleshooting capabilities

### 🔧 Improvements
- **Better Error Handling**: Automatic retry logic for Discord API calls
- **Enhanced API Monitoring**: More detailed ROTOM API status checking
- **Improved PID Detection**: Better process monitoring and restart logic
- **Performance Optimizations**: Reduced script complexity and improved efficiency

### 🐛 Bug Fixes
- **Fixed App Restart**: Apps now properly restart when monitoring detects issues
- **Improved Memory Monitoring**: Better memory threshold detection
- **Enhanced Device Detection**: More reliable device name matching with ROTOM API

---
## 📥 Installation for Non-PoGoROM Devices
### Step 1: Install Termux
Download Termux from F-Droid (recommended) or the Play Store.

### Step 2: Install jq and curl
Open Termux and run:
```
pkg update && pkg upgrade -y
pkg install jq curl -y
``` 
### Step 3: Verify Installation
Ensure the tools are accessible:
```
jq --version && curl --version
```
## ⚙️ Configuration
1. **Edit `config.json`**:  
   - Update `DISCORD_WEBHOOK_URL`, `ROTOM_URL`, etc.  
   - Use `config.example.json` as a template.  

2. **Place `config.json`**:  
   Copy to:
   ```
   /sdcard/Download/
   ````  

### Install the Magisk Module
## Method 1: Magisk Manager  
1. Download the module ZIP:  
   `MagiskFurtif-f3ger-3.2.zip`  
2. Open **Magisk Manager** → **Modules** → **Install from storage**.  
3. Select the ZIP and reboot.  

## Method 2: PixelFlasher (Advanced)  
1. Load the ZIP in PixelFlasher.  
2. Flash the module and reboot.  

---
