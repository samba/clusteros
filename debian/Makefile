# NB: this is only expected to work in another debian-like environment.


NEED_NONFREE_FIRMWARE := false
CODENAME := kubic

DEBIAN_VERSION := 11.4.0
DEBIAN_URL := http://debian-cd.debian.net/debian-cd/$(DEBIAN_VERSION)/multi-arch/iso-cd/debian-$(DEBIAN_VERSION)-amd64-i386-netinst.iso
DEBIAN_NONFREE_URL := https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/$(DEBIAN_VERSION)+nonfree/multi-arch/iso-cd/firmware-$(DEBIAN_VERSION)-amd64-i386-netinst.iso
DEBIAN_ISO := $(notdir $(DEBIAN_URL))
DEBIAN_NONFREE_ISO := $(notdir $(DEBIAN_NONFREE_URL))

MOUNT_SENTINEL := /tmp/mount.iso/.disk/info
MOUNT_PATH := /tmp/mount.iso
MKISOFS_SRC := $(MOUNT_PATH)/.disk/mkisofs
BASE_ISO := $(if $(filter-out true,$(NEED_NONFREE_FIRMWARE)),$(DEBIAN_ISO),$(DEBIAN_NONFREE_ISO))
OUTPUT_ISO := $(patsubst %.iso,%.$(CODENAME).iso,$(BASE_ISO))
OVERLAY_PATH := ./overlay
EXTRACT_PATH := ./extract

OVERLAY_FILES := $(shell find $(OVERLAY_PATH)/install -type f)
MBR_TEMPLATE := $(EXTRACT_PATH)/isohdpfx.bin

.PHONY: fetch-iso
fetch-iso: $(BASE_ISO)

.PHONY: mount
mount: $(MOUNT_SENTINEL)
$(MKISOFS_SRC) $(MOUNT_SENTINEL): $(BASE_ISO)
	mkdir -p $(MOUNT_PATH)
	mount | grep "$(BASE_ISO)" | grep $(MOUNT_PATH) || sudo mount -o loop -t iso9660 $< $(MOUNT_PATH)

unmount:
	mount | grep -v "$(BASE_ISO)" | grep -v $(MOUNT_PATH) ||  sudo umount $(MOUNT_PATH)




define II
initrds: $(OVERLAY_PATH)/install.$1/initrd.gz
$(MOUNT_PATH)/install.$1/initrd.gz: $(MOUNT_SENTINEL)

$(EXTRACT_PATH)/install.$1/initrd: $(MOUNT_PATH)/install.$1/initrd.gz |
	mkdir -p $$(dir $$@)
	gzip -cd $$< > $$@


$(OVERLAY_PATH)/install.$1/initrd.gz: $(OVERLAY_FILES)  | $(EXTRACT_PATH)/install.$1/initrd
	mkdir -p $$(dir $$@)
	cp -v $(EXTRACT_PATH)/install.$1/initrd $$(dir $$@)
	$$(eval targ=$$(basename $$(abspath $$@)))
	cd $(OVERLAY_PATH)/install && ls -1 | cpio -o -H newc -A -F $$(targ)
	gzip $$(basename $$@)


$(OUTPUT_ISO): $(OVERLAY_PATH)/install.$1/initrd.gz

endef

platforms := amd 386
$(foreach d,$(platforms),$(eval $(call II,$d)))


.PHONY: mkisofs
mkisofs: $(EXTRACT_PATH)/.disk/mkisofs
$(EXTRACT_PATH)/.disk/mkisofs: $(MKISOFS_SRC) $(MBR_TEMPLATE)
	mkdir -p $(dir $@)
	sed -E 's/\s-/\n\t-/g' $< | grep -v -e jigdo -e md5-list -e checksum_algorithm_iso -e '-o /'  > $@
	echo "\t-o $(OUTPUT_ISO)" >>$@
	sed -i -E 's@boot1 CD1@\n\t"$(MOUNT_PATH)"@g' $@
	sed -i -E 's@-isohybrid-mbr .*$$@-isohybrid-mbr $(MBR_TEMPLATE)@g' $@
	echo "\t-graft-points" >> $@
	echo "\t/install.amd/initrd.gz=$(OVERLAY_PATH)/install.amd/initrd.gz" >> $@
	echo "\t/install.386/initrd.gz=$(OVERLAY_PATH)/install.386/initrd.gz" >> $@
	sed -i -E 's/$$/ \\/g' $@
	echo >> $@


$(MBR_TEMPLATE): $(BASE_ISO)
	dd if=$< bs=1 count=432 of=$@

.PHONY: iso
iso: $(OUTPUT_ISO)
$(OUTPUT_ISO): $(EXTRACT_PATH)/.disk/mkisofs | $(MBR_TEMPLATE)
	bash -x $^

clean: unmount
	find $(OVERLAY_PATH) $(EXTRACT_PATH) -name 'initrd*'  -print -delete
	find $(EXTRACT_PATH) -name mkisofs -print -delete
	test \! -f $(OUTPUT_ISO) || rm -vf $(OUTPUT_ISO)


.DELETE_ON_ERROR: $(DEBIAN_ISO) $(DEBIAN_NONFREE_ISO)

$(DEBIAN_ISO): # NB: URLs aren't safe dependencies
	wget --continue -O "$@" "$(DEBIAN_URL)"

$(DEBIAN_NONFREE_ISO): # NB: URLs aren't safe dependencies
	wget --continue -O "$@" "$(DEBIAN_NONFREE_URL)"




