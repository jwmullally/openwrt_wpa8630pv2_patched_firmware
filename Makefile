# This Makefile downloads the OpenWRT ImageBuilder and patches
# the included tplink-safeloader to add more SupportList entries.
# Afterwards, the ImageBuilder can be used as normal.
#
# One advantage of this over from-source custom builds is that the 
# kernel is the same as the official builds, so all kmods from the 
# standard repos are installable.

ALL_CURL_OPTS := $(CURL_OPTS) -L --fail --create-dirs

VERSION := 22.03.6
BOARD := ath79
SUBTARGET := tiny
SOC := qca9563
BUILDER := openwrt-imagebuilder-$(VERSION)-$(BOARD)-$(SUBTARGET).Linux-x86_64
PROFILES := tplink_tl-wpa8630p-v2.0-eu tplink_tl-wpa8630p-v2.1-eu tplink_tl-wpa8630p-v2-int 

PACKAGES := luci wpad-basic luci-app-commands open-plc-utils-plctool open-plc-utils-plcrate open-plc-utils-hpavkeys -libustream-wolfssl -wpad-basic-wolfssl -ca-certificates -ppp -ppp-mod-pppoe -luci-proto-ppp

# v23.05 barely fits, but is almost unusable due to lack of space versus
# functionality gained, I'd recommend sticking with v22.03 for now.
#PACKAGES := luci -ca-certificates -ppp -ppp-mod-pppoe -luci-proto-ppp -uboot-envtools -ca-bundle -procd-seccomp

EXTRA_IMAGE_NAME := patch

BUILD_DIR := build
TOPDIR := $(CURDIR)/$(BUILD_DIR)/$(BUILDER)
KDIR := $(TOPDIR)/build_dir/target-mips_24kc_musl/linux-$(BOARD)_$(SUBTARGET)
PATH := $(TOPDIR)/staging_dir/host/bin:$(PATH)
LINUX_VERSION = $(shell sed -n -e '/Linux-Version: / {s/Linux-Version: //p;q}' $(BUILD_DIR)/$(BUILDER)/.targetinfo)
OUTPUT_DIR := $(BUILD_DIR)/$(BUILDER)/bin/targets/$(BOARD)/$(SUBTARGET)


all: images


$(BUILD_DIR)/downloads:
	mkdir -p $(BUILD_DIR)/downloads.tmp
	cd $(BUILD_DIR)/downloads.tmp && curl $(ALL_CURL_OPTS) -O https://downloads.openwrt.org/releases/$(VERSION)/targets/$(BOARD)/$(SUBTARGET)/$(BUILDER).tar.xz
	mv $(BUILD_DIR)/downloads.tmp $(BUILD_DIR)/downloads
$(BUILDER).tar.xz:


$(BUILD_DIR)/$(BUILDER): $(BUILD_DIR)/downloads
	cd $(BUILD_DIR) && tar -xf downloads/$(BUILDER).tar.xz
	
	# Fetch firmware utility sources to apply patches
	cd $(BUILD_DIR)/$(BUILDER) && curl $(ALL_CURL_OPTS) "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/tags/v21.02.3;a=blob_plain;f=tools/firmware-utils/src/tplink-safeloader.c" -o tools/firmware-utils/src/tplink-safeloader.c
	cd $(BUILD_DIR)/$(BUILDER) && curl $(ALL_CURL_OPTS) "https://git.openwrt.org/?p=openwrt/openwrt.git;hb=refs/tags/v21.02.3;a=blob_plain;f=tools/firmware-utils/src/md5.h" -o tools/firmware-utils/src/md5.h
	
	# Apply all patches
	$(foreach file, $(sort $(wildcard patches/*.patch)), patch -d $(BUILD_DIR)/$(BUILDER) --posix -p1 < $(file);)
	
	# Build tools
	cd $(BUILD_DIR)/$(BUILDER) && gcc -Wall -o staging_dir/host/bin/tplink-safeloader tools/firmware-utils/src/tplink-safeloader.c -lcrypto -lssl
	cd $(BUILD_DIR)/$(BUILDER) && ln -sf /usr/bin/cpp staging_dir/host/bin/mips-openwrt-linux-musl-cpp
	
	# Regenerate .targetinfo
	cd $(BUILD_DIR)/$(BUILDER) && touch staging_dir/host/.prereq-build
	cd $(BUILD_DIR)/$(BUILDER) && make -f include/toplevel.mk TOPDIR="$(TOPDIR)" prepare-tmpinfo || true
	cd $(BUILD_DIR)/$(BUILDER) && cp -f tmp/.targetinfo .targetinfo


$(BUILD_DIR)/linux-include: $(BUILD_DIR)/$(BUILDER)
	# Fetch DTS include dependencies
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/clock/ath79-clk.h?h=v$(LINUX_VERSION)" -o $(KDIR)/linux-$(LINUX_VERSION)/include/dt-bindings/clock/ath79-clk.h
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/gpio/gpio.h?h=v$(LINUX_VERSION)" -o $(KDIR)/linux-$(LINUX_VERSION)/include/dt-bindings/gpio/gpio.h
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/dt-bindings/input/input.h?h=v$(LINUX_VERSION)" -o $(KDIR)/linux-$(LINUX_VERSION)/include/dt-bindings/input/input.h
	curl $(ALL_CURL_OPTS) "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/uapi/linux/input-event-codes.h?h=v$(LINUX_VERSION)" -o $(KDIR)/linux-$(LINUX_VERSION)/include/dt-bindings/input/linux-event-codes.h
	touch $(BUILD_DIR)/linux-include


images: $(BUILD_DIR)/$(BUILDER) $(BUILD_DIR)/linux-include
	# Build this device's DTB and firmware kernel image. Uses the official kernel build as a base.
	cd $(BUILD_DIR)/$(BUILDER) && $(foreach PROFILE,$(PROFILES),\
	    env PATH=$(PATH) make --trace -C target/linux/$(BOARD)/image $(KDIR)/$(PROFILE)-kernel.bin TOPDIR="$(TOPDIR)" INCLUDE_DIR="$(TOPDIR)/include" TARGET_BUILD=1 BOARD="$(BOARD)" SUBTARGET="$(SUBTARGET)" PROFILE="$(PROFILE)" DEVICE_DTS="$(SOC)_$(PROFILE)"\
	;)
	
	# Use ImageBuilder as normal
	cd $(BUILD_DIR)/$(BUILDER) && $(foreach PROFILE,$(PROFILES),\
	    make image PROFILE="$(PROFILE)" EXTRA_IMAGE_NAME="$(EXTRA_IMAGE_NAME)" PACKAGES="$(PACKAGES)" FILES="../../rootfs/"\
	;)
	cat $(OUTPUT_DIR)/sha256sums
	ls -hs $(OUTPUT_DIR)


clean:
	rm -rf build
