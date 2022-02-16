## Overview

This repository contains a simple patch to enable the [OpenWRT firmware for the TP-Link TL-WPA8630P v2](https://openwrt.org/toh/tp-link/tl-wpa8630p_v2) to be flashed to the following devices which are not officially supported. It also includes [this upcoming patch](https://github.com/openwrt/openwrt/pull/4500) to move the device from ath79-generic to ath79-tiny to support LuCi builds and have 1MB free space on the device.

It builds the images using the [OpenWRT ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder). One advantage of this over from-source custom builds is that the kernel is the same as the official builds, so all kmods from the standard repos are installable.

The only difference between these firmwares and the offical firmwares is the extra model version in the firmware file's SupportList required to perform the upgrade. After installing, the device will be identical to the official OpenWRT image (i.e. `v2-int`, `v2.0-eu`, `v2.1-eu`). You can upgrade using the official sysupgrade firmwares matching the patched firmware. If you are reverting to stock later, make sure to use the exact same stock firmware version as you originally upgraded from. 

**NOTE 2022 Q1: Wait until the Pull Request above is merged before sysupgrading back to the official images, as the official images are still too large.**


## Supported versions 

| Hardware Version | Stock Firmware Version | Patched OpenWRT Firmware |
| --- | --- | --- |
| `Model: TL-WPA8630P(AU) v2.0` | All | `openwrt-patch-ath79-tiny-tplink_tl-wpa8630p-v2-int-squashfs-factory.bin` |
| `Model: TL-WPA8630P(AU) v2.1` | All | `openwrt-patch-ath79-tiny-tplink_tl-wpa8630p-v2-int-squashfs-factory.bin` |
| `Model: TL-WPA8630P(DE) v2.0` | All | `openwrt-patch-ath79-tiny-tplink_tl-wpa8630p-v2-int-squashfs-factory.bin` |
| `Model: TL-WPA8630P(EU) v2.0` | All | `openwrt-patch-ath79-tiny-tplink_tl-wpa8630p-v2.0-eu-squashfs-factory.bin` |
| `Model: TL-WPA8630P(EU) v2.1` | All | `openwrt-patch-ath79-tiny-tplink_tl-wpa8630p-v2.1-eu-squashfs-factory.bin` |
| `Model: TL-WPA8630(CA) Ver: 2.0` | All | `openwrt-patch-ath79-tiny-tplink_tl-wpa8630p-v2-int-squashfs-factory.bin` |
| `Model: TL-WPA8630(US) Ver: 2.0` | `2.0.1 Build 20171011 Rel.33916` | `openwrt-patch-ath79-tiny-tplink_tl-wpa8630p-v2-int-squashfs-factory.bin` |
| `Model: TL-WPA8630(EU) Ver: 2.0` | `2.0.2 Build 20171017 Rel.43480` | `openwrt-patch-ath79-tiny-tplink_tl-wpa8630p-v2.0-eu-squashfs-factory.bin` |

**!!! ONLY INSTALL THESE FIRMWARES IF YOUR CURRENT HARDWARE AND FIRMWARE VERSIONS EXACTLY MATCHES THE ENTRY IN THIS TABLE !!!**

If your device is running a different firmware version than those listed below, installing these firmwares will prevent your device from booting and turn it into a [brick](https://en.wikipedia.org/wiki/Brick_%28electronics%29). This is because the bootloader in the newer versions of the stock firmwares load the kernal and filesystem from a different memory location. It will not be recoverable without physically opening the device (which should not be attempted as it contains hazardous 110-230V voltages) and writing directly to the flash memory chip with a flash programmer. So only install this firmware on your device if its a complete match! For support for other versions, ask in the [OpenWRT forum](https://forum.openwrt.org/).

Where to find this information:

* Hardware Version 
  * Where: On the barcode sticker on the back of the device.
  * Example: `Model: TL-WPA8630P(EU) Ver: 2.0`
* Firmware Version
  * Where: In the Web UI of the device under "System Tools -> Firmware Upgrade"
  * Example: `2.0.3 Build 20171018 Rel.36564`


## Download firmware

See the [releases page](https://github.com/jwmullally/openwrt_wpa8630pv2_patched_firmware/releases/) for links to the firmware images.

These are built using [this Github workflow](./.github/workflows/build_release_images.yml). You can see the build logs [here](https://github.com/jwmullally/openwrt_wpa8630pv2_patched_firmware/actions?query=workflow%3ABuild-Release-Images).


## Installing

Choose the correct file from the table above and follow the [standard installation instructions](https://openwrt.org/toh/tp-link/tl-wpa8630p_v2#oem_easy_installation).

If you get "Wrong file" message during firmware upgrade, try renaming the file to something shorter like `openwrt-firmware.bin`.


## Building

If you want to build the firmwares yourself, checkout this repo and do the following.

```
make
```

The firmware will be located at `openwrt-imagebuilder-ath79-tiny.Linux-x86_64/bin/targets/ath79/tiny/`. To customize the firmware further (packages etc), see the ImageBuilder wiki.
