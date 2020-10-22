# This Makefile downloads the OpenWRT ImageBuilder and patches
# the included tplink-safeloader to add more SupportList entries.
# Afterwards, the ImageBuilder can be used as normal.
#
# One advantage of this over from-source custom builds is that the 
# kernel is the same as the official builds, so all kmods from the 
# standard repos are installable.

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
		make image PROFILE="tplink_tl-wpa8630p-v2.0-eu" EXTRA_IMAGE_NAME="patch" PACKAGES="procd iw luci -ppp -ppp-mod-pppoe"
	cd openwrt-imagebuilder-ath79-generic.Linux-x86_64 && \
		make image PROFILE="tplink_tl-wpa8630p-v2-int" EXTRA_IMAGE_NAME="patch" PACKAGES="procd iw luci -ppp -ppp-mod-pppoe"
	cat openwrt-imagebuilder-ath79-generic.Linux-x86_64/bin/targets/ath79/generic/sha256sums 
	ls -hs openwrt-imagebuilder-ath79-generic.Linux-x86_64/bin/targets/ath79/generic/openwrt-patch-*-factory.bin


clean:
	rm -rf openwrt-imagebuilder-ath79-generic.Linux-x86_64
	rm -f openwrt-imagebuilder-ath79-generic.Linux-x86_64.tar.xz
	rm -f md5.h
	rm -f tplink-safeloader.c
