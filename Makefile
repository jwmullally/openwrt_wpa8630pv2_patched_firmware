# This Makefile downloads the OpenWRT ImageBuilder and patches
# the included tplink-safeloader to add more SupportList entries.
# Afterwards, the ImageBuilder can be used as normal.
#
# One advantage of this over from-source custom builds is that the 
# kernel is the same as the official builds, so all kmods from the 
# standard repos are installable.

# This device only has 6016k of usable memory. Remove PPP and add in
# relevant PLC utilities.
PACKAGES = luci luci-app-commands open-plc-utils-plctool open-plc-utils-plcrate open-plc-utils-hpavkeys 
PACKAGES += -ppp -ppp-mod-pppoe

VERSION = 21.02.0-rc1

all: images


openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64:
	curl ${CURL_OPTS} -C - -L -O https://downloads.openwrt.org/releases/$(VERSION)/targets/ath79/generic/openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64.tar.xz
	tar -xf openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64.tar.xz
	curl ${CURL_OPTS} -L -O "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/heads/master;a=blob_plain;f=tools/firmware-utils/src/tplink-safeloader.c"
	curl ${CURL_OPTS} -L -O "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/heads/master;a=blob_plain;f=tools/firmware-utils/src/md5.h"
	patch -p0 < tplink-safeloader.patch
	gcc -Wall -o openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64/staging_dir/host/bin/tplink-safeloader tplink-safeloader.c -lcrypto -lssl


images: openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64
	cd openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64 && \
		make image PROFILE="tplink_tl-wpa8630p-v2.0-eu" EXTRA_IMAGE_NAME="patch" PACKAGES="${PACKAGES}" CONFIG_IPV6=n
	cd openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64 && \
		make image PROFILE="tplink_tl-wpa8630p-v2.1-eu" EXTRA_IMAGE_NAME="patch" PACKAGES="${PACKAGES}" CONFIG_IPV6=n
	cd openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64 && \
		make image PROFILE="tplink_tl-wpa8630p-v2-int" EXTRA_IMAGE_NAME="patch" PACKAGES="${PACKAGES}"
	cat openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64/bin/targets/ath79/generic/sha256sums 
	ls -hs openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64/bin/targets/ath79/generic/openwrt-*-patch-*-factory.bin


clean:
	rm -rf openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64
	rm -f openwrt-imagebuilder-$(VERSION)-ath79-generic.Linux-x86_64.tar.xz
	rm -f md5.h
	rm -f tplink-safeloader.c
