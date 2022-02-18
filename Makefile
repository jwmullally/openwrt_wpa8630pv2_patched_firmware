# This Makefile downloads the OpenWRT ImageBuilder and patches
# the included tplink-safeloader to add more SupportList entries.
# Afterwards, the ImageBuilder can be used as normal.
#
# One advantage of this over from-source custom builds is that the 
# kernel is the same as the official builds, so all kmods from the 
# standard repos are installable.

ALL_CURL_OPTS := $(CURL_OPTS) -L --fail --create-dirs

VERSION := 21.02.1
BOARD := ath79
SUBTARGET := tiny
SOC := qca9563
BUILDER := openwrt-imagebuilder-$(VERSION)-$(BOARD)-$(SUBTARGET).Linux-x86_64
PROFILES := tplink_tl-wpa8630p-v2.0-eu tplink_tl-wpa8630p-v2.1-eu tplink_tl-wpa8630p-v2-int
PACKAGES := luci
EXTRA_IMAGE_NAME := patch

TOPDIR := $(CURDIR)/$(BUILDER)
KDIR := $(TOPDIR)/build_dir/target-mips_24kc_musl/linux-$(BOARD)_$(SUBTARGET)
PATH := $(TOPDIR)/staging_dir/host/bin:$(PATH)
LINUX_VERSION = $(shell sed -n -e '/Linux-Version: / {s/Linux-Version: //p;q}' $(BUILDER)/.targetinfo)


all: images


$(BUILDER).tar.xz:
	curl $(ALL_CURL_OPTS) -O https://downloads.openwrt.org/releases/$(VERSION)/targets/$(BOARD)/$(SUBTARGET)/$(BUILDER).tar.xz


$(BUILDER): $(BUILDER).tar.xz
	tar -xf $(BUILDER).tar.xz
	
	# Fetch firmware utility sources to apply patches
	curl $(ALL_CURL_OPTS) "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/tags/v$(VERSION);a=blob_plain;f=tools/firmware-utils/src/tplink-safeloader.c" -o $(BUILDER)/tools/firmware-utils/src/tplink-safeloader.c
	curl $(ALL_CURL_OPTS) "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/tags/v$(VERSION);a=blob_plain;f=tools/firmware-utils/src/md5.h" -o $(BUILDER)/tools/firmware-utils/src/md5.h
	
	# Apply all patches
	cd $(BUILDER) && patch -p1 < ../0001-tplink-safeloader.patch
	cd $(BUILDER) && patch -p1 < ../0002-ath79-Move-TPLink-WPA8630Pv2-to-ath79-tiny-target.patch
	gcc -Wall -o $(TOPDIR)/staging_dir/host/bin/tplink-safeloader $(BUILDER)/tools/firmware-utils/src/tplink-safeloader.c -lcrypto -lssl
	
	# Regenerate .targetinfo
	cd $(BUILDER) && make -f include/toplevel.mk TOPDIR="$(TOPDIR)" prepare-tmpinfo || true
	cp -f $(BUILDER)/tmp/.targetinfo $(BUILDER)/.targetinfo


linux-sources: $(BUILDER)
	# Fetch DTS includes and other kernel source files
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/clock/ath79-clk.h?h=v$(LINUX_VERSION)" -o linux-sources.tmp/include/dt-bindings/clock/ath79-clk.h
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/gpio/gpio.h?h=v$(LINUX_VERSION)" -o linux-sources.tmp/include/dt-bindings/gpio/gpio.h
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/input/input.h?h=v$(LINUX_VERSION)" -o linux-sources.tmp/include/dt-bindings/input/input.h
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/uapi/linux/input-event-codes.h?h=v$(LINUX_VERSION)" -o linux-sources.tmp/include/dt-bindings/input/linux-event-codes.h
	mv -T linux-sources.tmp linux-sources


images: $(BUILDER) linux-sources
	# Build this device's DTB and firmware kernel image. Uses the official kernel build as a base.
	ln -sf /usr/bin/cpp $(BUILDER)/staging_dir/host/bin/mips-openwrt-linux-musl-cpp
	ln -sf ../../../../../linux-sources/include $(KDIR)/linux-$(LINUX_VERSION)/include
	cd $(BUILDER) && $(foreach PROFILE,$(PROFILES),\
	    env PATH=$(PATH) make --trace -C target/linux/$(BOARD)/image $(KDIR)/$(PROFILE)-kernel.bin TOPDIR="$(TOPDIR)" INCLUDE_DIR="$(TOPDIR)/include" TARGET_BUILD=1 BOARD="$(BOARD)" SUBTARGET="$(SUBTARGET)" PROFILE="$(PROFILE)" DEVICE_DTS="$(SOC)_$(PROFILE)"\
	;)
	
	# Use ImageBuilder as normal
	cd $(BUILDER) && $(foreach PROFILE,$(PROFILES),\
	    make image PROFILE="$(PROFILE)" EXTRA_IMAGE_NAME="$(EXTRA_IMAGE_NAME)" PACKAGES="$(PACKAGES)" FILES="$(TOPDIR)/target/linux/$(BOARD)/$(SUBTARGET)/base-files/"\
	;)
	cat $(BUILDER)/bin/targets/$(BOARD)/$(SUBTARGET)/sha256sums
	ls -hs $(BUILDER)/bin/targets/$(BOARD)/$(SUBTARGET)/openwrt-*.bin


clean:
	rm -rf openwrt-imagebuilder-* linux-sources linux-sources.tmp
