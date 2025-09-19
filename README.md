# MagiskFurtif [![Magisk Module](https://github.com/Furtif/magisk-furtif/actions/workflows/magisk_module.yml/badge.svg)](https://github.com/Furtif/magisk-furtif/actions/workflows/magisk_module.yml)

## Description

Runs apk-tools on boot with magisk. 

For more information on frida, see https://www.frida.re/docs/android/.

## Instructions

Flash the zip for your platform using TWRP or Magisk Manager.

You can either grab the zip file from the [release page](https://github.com/Furtif/magisk-furtif/releases) or build it yourself.

I recommend using [Termux](https://play.google.com/store/apps/details?id=com.termux) to have the necessary dependencies for the proper functioning of the script, and to make sure that `curl` and `jq` are properly installed.

### Setup Instructions
This script is designed to work with the Termux environment on Android devices. Depending on your device and Android version, you might need to modify the path to the Termux [binary directory](https://github.com/Furtif/magisk-furtif/blob/main/base/common/service.sh#L13).

### Termux Binary Directory Path
The path to the Termux binary directory may vary based on your Android version or device type. Below are the typical paths for different scenarios:

### For Android 14 or specific versions:
- Termux binaries are usually located at:
  - /data/data/com.termux/files/usr/bin

### For ATV devices (e.g., H96):
- You might need to set the path to:
  - /system/xbin

### For other devices:
- The binaries could be located in:
  - /vendor/bin or /system/bin

### Alternatively:
- If you are using Termux from the Play Store, it can be found at:
  - /data/data/com.termux/files/usr/bin

Make sure to update the path in the script to match the correct directory for your device. This ensures that the script will work properly regardless of changes in the system's setup.


### In Termux terminal type:
```
pkg install curl
pkg install jq
```

### In order to build it:

```
git clone https://github.com/Furtif/magisk-furtif
cd magisk-furtif
edit base/common/service.sh
python3 build.py
```

Zip fils will be generated in builds.