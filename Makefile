# This Makefile downloads the OpenWRT ImageBuilder and patches
# the included tplink-safeloader to add more SupportList entries.
# Afterwards, the ImageBuilder can be used as normal.
#
# One advantage of this over from-source custom builds is that the 
# kernel is the same as the official builds, so all kmods from the 
# standard repos are installable.

# This device only has 6016k of usable memory. WolfSSL was recently made
# default to support WPA3 and 802.11s SAE, but it is too large to fit
# alongside LuCI, so swap back to Mbed TLS. Also remove PPP and add in
# relevant PLC utilities.
PACKAGES = procd iw luci -wpad-basic-wolfssl wpad-basic -libustream-wolfssl libustream-mbedtls -ppp -ppp-mod-pppoe luci-app-commands open-plc-utils-plctool open-plc-utils-plcrate open-plc-utils-hpavkeys

all: images


openwrt-imagebuilder-ath79-generic.Linux-x86_64:
	curl ${CURL_OPTS} -C - -L -O https://downloads.openwrt.org/snapshots/targets/ath79/generic/openwrt-imagebuilder-ath79-generic.Linux-x86_64.tar.xz
	tar -xf openwrt-imagebuilder-ath79-generic.Linux-x86_64.tar.xz
	curl ${CURL_OPTS} -L -O "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/heads/master;a=blob_plain;f=tools/firmware-utils/src/tplink-safeloader.c"
	curl ${CURL_OPTS} -L -O "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/heads/master;a=blob_plain;f=tools/firmware-utils/src/md5.h"
	patch -p0 < tplink-safeloader.patch
	gcc -Wall -o openwrt-imagebuilder-ath79-generic.Linux-x86_64/staging_dir/host/bin/tplink-safeloader tplink-safeloader.c -lcrypto -lssl


images: openwrt-imagebuilder-ath79-generic.Linux-x86_64
	cd openwrt-imagebuilder-ath79-generic.Linux-x86_64 && \
		make image PROFILE="tplink_tl-wpa8630p-v2.0-eu" EXTRA_IMAGE_NAME="patch" PACKAGES="${PACKAGES}"
	cd openwrt-imagebuilder-ath79-generic.Linux-x86_64 && \
		make image PROFILE="tplink_tl-wpa8630p-v2.1-eu" EXTRA_IMAGE_NAME="patch" PACKAGES="${PACKAGES}"
	cd openwrt-imagebuilder-ath79-generic.Linux-x86_64 && \
		make image PROFILE="tplink_tl-wpa8630p-v2-int" EXTRA_IMAGE_NAME="patch" PACKAGES="${PACKAGES}"
	cat openwrt-imagebuilder-ath79-generic.Linux-x86_64/bin/targets/ath79/generic/sha256sums 
	ls -hs openwrt-imagebuilder-ath79-generic.Linux-x86_64/bin/targets/ath79/generic/openwrt-patch-*-factory.bin


clean:
	rm -rf openwrt-imagebuilder-ath79-generic.Linux-x86_64
	rm -f openwrt-imagebuilder-ath79-generic.Linux-x86_64.tar.xz
	rm -f md5.h
	rm -f tplink-safeloader.c
