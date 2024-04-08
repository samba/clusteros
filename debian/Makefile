# NB: this requires `xorriso` which can be installed on MacOS via Homebrew

NEED_NONFREE_FIRMWARE := false
CODENAME := kubic

ARCH=amd64
# ARCH=i386

DEBIAN_VERSION := 12.5.0
DEBIAN_URL := https://cdimage.debian.org/debian-cd/current/$(ARCH)/iso-cd/debian-$(DEBIAN_VERSION)-$(ARCH)-netinst.iso
DEBIAN_ISO := $(notdir $(DEBIAN_URL))

OUTPUT_ISO := $(patsubst %.iso,%.$(CODENAME).iso,$(DEBIAN_ISO))
OVERLAY_PATH := ./overlay
EXTRACT_PATH := ./extract

# BOOTCFG_FILES := $(shell find $(EXTRACT_PATH)/isolinux/ -name '*.cfg' -print0 | xargs -0 grep -l 'Automated install')

OVERLAY_FILES := $(shell find $(OVERLAY_PATH)/install -type f)
MBR_TEMPLATE := $(EXTRACT_PATH)/isohdpfx.bin

.PHONY: fetch-iso
fetch-iso: $(DEBIAN_ISO)

# Template for copying individual files from the ISO without a mount
define isocp
$(2)/$(1): $(DEBIAN_ISO) ;
	mkdir -p $$(dir $$@)
	test -s $$@ && exit || \
		xorriso -osirrox on  -indev $(DEBIAN_ISO)  -extract $(1) $(2)/$(1)
	chmod -R ug+w $$@
endef



extract: $(DEBIAN_ISO)
	mkdir -p $@
	xorriso -osirrox on -indev $(DEBIAN_ISO) -extract / $(EXTRACT_PATH)

$(EXTRACT_PATH)/.disk/mkisofs $(EXTRACT_PATH)/isolinux/isolinux.bin: extract

define BC
$(OVERLAY_PATH)/isolinux/$1: $(EXTRACT_PATH)/isolinux/$1 ;
	mkdir -p $$(dir $$@)
	sed -E 's@(append auto=true)@\1 file=/cdrom/preseed.cfg@;' < $$^ > $$@

$(OVERLAY_PATH)/.disk/mkisofs: $(OVERLAY_PATH)/isolinux/$1

endef

# extraction rules for each boot config file
bootfiles := adgtk addrkgtk adtxt addrk adspkgtk
$(foreach b,$(bootfiles),$(eval $(call isocp,isolinux/$(b).cfg,extract)))
$(foreach b,$(bootfiles),$(eval $(call BC,$(b).cfg)))


define II
initrds: $(OVERLAY_PATH)/install.$1/initrd.gz

# generate an updated initrd for $1
$(OVERLAY_PATH)/install.$1/initrd.gz: $(EXTRACT_PATH)/install.$1/initrd.gz | extract
	mkdir -p $$(dir $$@)
	mkdir -p $(EXTRACT_PATH)/$1/initrd.extract
	cd $(EXTRACT_PATH)/$1/initrd.extract; gzip -cd $$(abspath $$<) | cpio --quiet -z -i
	cp -av $(OVERLAY_PATH)/install/preseed.cfg $(EXTRACT_PATH)/$1/initrd.extract/preseed.cfg
	cd $(EXTRACT_PATH)/$1/initrd.extract; find . | cpio --quiet -o -R root: -H newc -z -F $$(abspath $$@)
	rm -rf $(EXTRACT_PATH)/$1


$(EXTRACT_PATH)/install.$1/initrd.gz: extract

# $(OUTPUT_ISO): $(OVERLAY_PATH)/install.$1/initrd.gz

endef

platforms := amd 386
$(foreach d,$(platforms),$(eval $(call II,$d)))



$(OVERLAY_PATH)/install/preseed.cfg: preseed.cfg.template preseed_template_vars.sh
	eval $$(cat ./preseed_template_vars.sh) ; envsubst < $^ > $@

.PHONY: diff
diff:
	for i in amd 386; do command diff -r {extract,overlay}/install.$${i}; done

.PHONY: mkisofs
mkisofs: $(OVERLAY_PATH)/.disk/mkisofs
$(OVERLAY_PATH)/.disk/mkisofs: $(EXTRACT_PATH)/.disk/mkisofs $(MBR_TEMPLATE) $(OVERLAY_PATH)/install/preseed.cfg
	mkdir -p $(dir $@)
	sed -E 's/[ ]-/\n\t-/g' $< | grep -v -e jigdo -e checksum-list -e checksum_algorithm -e '-o /'  > $@  # drop problem args
	echo -e "\t-o $(OUTPUT_ISO)" >>$@  # add output
	sed -ibak -E 's@boot1 CD1@\n\t"$(EXTRACT_PATH)"@g' $@
	sed -ibak -E 's@-isohybrid-mbr .*$$@-isohybrid-mbr $(MBR_TEMPLATE)@g' $@
	echo -e "\t-graft-points" >> $@
	# echo "\t/install.amd/initrd.gz=$(OVERLAY_PATH)/install.amd/initrd.gz" >> $@
	# echo "\t/install.386/initrd.gz=$(OVERLAY_PATH)/install.386/initrd.gz" >> $@
	echo -e "\t/preseed.cfg=$(OVERLAY_PATH)/install/preseed.cfg" >> $@
	echo -e "\t/bootstrap.sh=bootstrap.sh" >> $@
	echo -e "\t/.disk/mksisofs=$@" >>$@
	echo -e $(foreach b,$(bootfiles),"\t/isolinux/$(b).cfg=$(OVERLAY_PATH)/isolinux/$(b).cfg") >> $@
	sed -ibak  -E 's/$$/ \\/g' $@
	echo >> $@


$(MBR_TEMPLATE): $(DEBIAN_ISO)
	mkdir -p $(dir $@)
	dd if=$< bs=1 count=432 of=$@

.PHONY: iso
iso: $(OUTPUT_ISO)
$(OUTPUT_ISO): $(OVERLAY_PATH)/.disk/mkisofs $(EXTRACT_PATH)/isolinux/isolinux.bin | $(MBR_TEMPLATE)
	bash -x $<

clean:
	sudo rm -rf $(EXTRACT_PATH)  # NB: extracted paths may be read-only
	rm -rf $(OVERLAY_PATH)/isolinux/*.cfg
	rm -rf $(OVERLAY_PATH)/.disk/mkisofs $(OVERLAY_PATH)/install.*/initrd.gz
	test \! -f $(OUTPUT_ISO) || rm -vf $(OUTPUT_ISO)


.DELETE_ON_ERROR: $(DEBIAN_ISO)

$(DEBIAN_ISO): # NB: URLs aren't safe dependencies
	wget --continue -O "$@" "$(DEBIAN_URL)"





