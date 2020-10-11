## Overview

This repository contains a simple patch to enable the [OpenWRT firmware for the TP-Link TL-WPA8630P v2](https://openwrt.org/toh/tp-link/tp-link_tl-wpa8630p_v2) to be flashed to the following devices which are not officially supported. 

It builds the images using the [OpenWRT ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder). One advantage of this over from-source custom builds is that the kernel is the same as the official builds, so all kmods from the standard repos are installable.

The only difference between these firmwares and the offical firmwares is the extra model version in the firmware file's SupportList required to perform the upgrade. After installing, the device will be identical to its OpenWRT counterpart. You can upgrade using the official sysupgrade firmwares matching the patched firmware. If you are reverting to stock later, make sure to use the exact same stock firmware version as you originally upgraded from.

These firmwares are build using the OpenWRT Snapshot release. When stable versions are released for this device, this repo will be updated to include them. 


## Supported versions 

| Hardware Version | Stock Firmware Version | Patched OpenWRT Firmware |
| --- | --- | --- |
| `Model: TL-WPA8630(CA) Ver: 2.0` | `2.0.1 Build 20171107 Rel.62737` | `openwrt-patch-ath79-generic-tplink_tl-wpa8630p-v2-int-squashfs-factory.bin` |
| `Model: TL-WPA8630(US) Ver: 2.0` | `2.0.1 Build 20171011 Rel.33916` | `openwrt-patch-ath79-generic-tplink_tl-wpa8630p-v2-int-squashfs-factory.bin` |
| `Model: TL-WPA8630(EU) Ver: 2.0` | `2.0.2 Build 20171017 Rel.43480` | `openwrt-patch-ath79-generic-tplink_tl-wpa8630p-v2.0-eu-squashfs-factory.bin` |

**!!! ONLY INSTALL THESE FIRMWARES IF YOUR HARDWARE AND FIRMWARE EXACTLY MATCHES THE ENTRY IN THIS TABLE !!!**

If your device is running a different firmware version than those listed below, installing these firmwares will prevent your device from booting and turn it into a [brick](https://en.wikipedia.org/wiki/Brick_(electronics). This is because the bootloader in the newer versions of the stock firmwares load the kernal and filesystem from different memory locations. It will not be recoverable without physically opening the device (which should not be attempted as it contains hazardous 110-230V voltages) and writing directly to the flash memory chip with a flash programmer. So only install this firmware on your device if its a complete match!

Where to find this information:

* Hardware Version 
  * Where: On the barcode sticker on the back of the device.
  * Example: `Model: TL-WPA8630P(EU) Ver: 2.0`
* Firmware Version
  * Where: In the Web UI of the device under "System Tools -> Firmware Upgrade"
  * Example: `2.0.3 Build 20171018 Rel.36564`


## Pre-built firmwares

*TODO: using Github actions*


## Installing

Choose the correct file from the table above and follow the (standard installation instructions)[https://openwrt.org/toh/tp-link/tp-link_tl-wpa8630p_v2#oem_easy_installation]

If you get "Wrong file" message during firmware upgrade, try renaming the file to something shorter like `openwrt-firmware.bin`.


## Building

If you want to build the firmwares yourself, checkout this repo and do the following.

```
make
```

The built firmware will be located at `openwrt-imagebuilder-ath79-generic.Linux-x86_64/bin/targets/ath79/generic/`. To customize the firmware further (packages etc), see the ImageBuilder wiki.
