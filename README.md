# MagiskFurtif

## Description

Runs apk-tools on boot with magisk. 

For more information on frida, see https://www.frida.re/docs/android/.

## Instructions

Flash the zip for your platform using TWRP or Magisk Manager.

You can either grab the zip file from the [release page](https://github.com/Furtif/magisk-furtif/releases) or build it yourself.

I recommend using [Termux](https://play.google.com/store/apps/details?id=com.termux) to have the necessary dependencies for the proper functioning of the script, and to make sure that `curl` and `jq` are properly installed.

In Termux terminal type:
```
pkg install curl
pkg install jq
```

In order to build it:

```
git clone https://github.com/Furtif/magisk-furtif
cd magisk-furtif
edit base/common/service.sh
python3 build.py
```

```
usage: build.py [-h] [-n NAME] [-c CLONE]

options:
  -h, --help                    show this help message and exit
  -n NAME, --name NAME          Name for clone.
  -c CLONE, --clone CLONE       Number for clones.
```

Zip fils will be generated in builds.
