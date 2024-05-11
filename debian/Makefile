# NB: this requires `xorriso` which can be installed on MacOS via Homebrew

NEED_NONFREE_FIRMWARE := false
CODENAME := kubic

ARCH=amd64
QEMU=qemu-system-x86_64
# ARCH=i386
# ARCH=qemu-system-i386

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


# Exposes the entire CD image content
extract: $(DEBIAN_ISO)
	mkdir -p $@
	xorriso -osirrox on -indev $(DEBIAN_ISO) -extract / $(EXTRACT_PATH)

$(EXTRACT_PATH)/.disk/mkisofs $(EXTRACT_PATH)/isolinux/isolinux.bin: extract

# translates a boot configuration to insert the preseed config
define BC
$(OVERLAY_PATH)/isolinux/$1: $(EXTRACT_PATH)/isolinux/$1 ;
	mkdir -p $$(dir $$@)
	sed -E 's@(append auto=true)@\1 file=/cdrom/preseed.cfg@; /^timeout/d; /^ontimeout/d; /^menu autoboot/d; s@include stdmenu.cfg@&\ninclude auto.cfg@;' < $$^ > $$@

# register dependency
$(OVERLAY_PATH)/.disk/mkisofs: $(OVERLAY_PATH)/isolinux/$1

endef

# extraction rules for each boot config file
bootfiles := adgtk addrkgtk adtxt addrk adspkgtk spkgtk menu
$(foreach b,$(bootfiles),$(eval $(call isocp,isolinux/$(b).cfg,$(EXTRACT_PATH))))
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

# inject preseed into the initramfs
# not necessary... it can read from cdrom
# $(OUTPUT_ISO): $(OVERLAY_PATH)/install.$1/initrd.gz

endef

platforms := amd 386
# $(foreach d,$(platforms),$(eval $(call II,$d))) # XXX: no longer required

.PRECIOUS: $(OVERLAY_PATH)/ssh/id_rsa $(OVERLAY_PATH)/ssh/id_rsa.pub
$(OVERLAY_PATH)/ssh/id_rsa $(OVERLAY_PATH)/ssh/id_rsa.pub:
	mkdir -p $(dir $@)
	test -f $@ || ssh-keygen -b 4096 -C "root@$(CODENAME)" -f $@


.PRECIOUS: $(OVERLAY_PATH)/ssh/authorized_keys
$(OVERLAY_PATH)/ssh/authorized_keys: $(OVERLAY_PATH)/ssh/id_rsa.pub
	test -s $@ || cp -v $< $@

SHELL=/bin/bash
$(OVERLAY_PATH)/install/preseed.cfg: preseed.cfg.template preseed_template_vars.sh
	export USER=$(CODENAME) ; \
		source ./preseed_template_vars.sh 2> $@.creds; \
		source ./config/bootstrap.sh ; \
		export KUBERNETES_VERSION ; \
		envsubst < $< > $@

.PHONY: diff
diff:
	for i in amd 386; do command diff -r {extract,overlay}/install.$${i}; done

$(OVERLAY_PATH)/boot/grub/grub.cfg: $(EXTRACT_PATH)/boot/grub/grub.cfg
	mkdir -p $(dir $@)
	awk -f ./boot-edit.awk $< > $@

.PHONY: mkisofs
mkisofs: $(OVERLAY_PATH)/.disk/mkisofs
$(OVERLAY_PATH)/.disk/mkisofs: | $(OVERLAY_PATH)/install/preseed.cfg $(OVERLAY_PATH)/ssh/authorized_keys
$(OVERLAY_PATH)/.disk/mkisofs: $(EXTRACT_PATH)/.disk/mkisofs $(MBR_TEMPLATE)
	mkdir -p $(dir $@)
	sed -E 's/[ ]-/\n\t-/g' $< | grep -v -e jigdo-template -e jigdo -e checksum-list -e checksum_algorithm   -e '-o /'  > $@  # drop problem args
	echo -e "\t-o $(OUTPUT_ISO)" >>$@  # add output
	echo -e "\t-m initrd.extract" >> $@ # exclude path
	sed -ibak -E 's@boot1 CD1@\n\t"$(EXTRACT_PATH)"@g' $@  # the main source path
	sed -ibak -E 's@-isohybrid-mbr .*$$@-isohybrid-mbr $(MBR_TEMPLATE)@g' $@
	echo -e "\t-graft-points" >> $@
	# echo "\t/install.amd/initrd.gz=$(OVERLAY_PATH)/install.amd/initrd.gz" >> $@
	# echo "\t/install.386/initrd.gz=$(OVERLAY_PATH)/install.386/initrd.gz" >> $@
	echo -e "\t/boot/grub/grub.cfg=$(OVERLAY_PATH)/boot/grub/grub.cfg" >> $@
	echo -e "\t/preseed.cfg=$(OVERLAY_PATH)/install/preseed.cfg" >> $@
	echo -e "\t/preseed.credentials=$(OVERLAY_PATH)/install/preseed.cfg.creds" >> $@
	echo -e "\t/firstboot.service=firstboot.service" >> $@
	echo -e "\t/kube/bootstrap.conf.sh=config/bootstrap.sh" >> $@
	echo -e "\t/firstboot.sh=firstboot.sh" >> $@
	echo -e "\t/ssh=$(OVERLAY_PATH)/ssh" >> $@
	echo -e "\t/.disk/mksisofs=$@" >>$@
	echo -e "\t/isolinux/auto.cfg=isolinux_auto.cfg" >> $@
	echo -e $(foreach b,$(bootfiles),"\t/isolinux/$(b).cfg=$(OVERLAY_PATH)/isolinux/$(b).cfg") >> $@
	sed -ibak  -E 's/$$/ \\/g' $@
	echo >> $@


$(MBR_TEMPLATE): $(DEBIAN_ISO)
	mkdir -p $(dir $@)
	dd if=$< bs=1 count=432 of=$@

.PHONY: iso
iso: $(OUTPUT_ISO)
$(OUTPUT_ISO): $(OVERLAY_PATH)/ssh/authorized_keys
$(OUTPUT_ISO): $(EXTRACT_PATH)/isolinux/isolinux.bin
$(OUTPUT_ISO): $(OVERLAY_PATH)/install/preseed.cfg
$(OUTPUT_ISO): $(OVERLAY_PATH)/boot/grub/grub.cfg
$(OUTPUT_ISO): firstboot.sh config/bootstrap.sh firstboot.service
$(OUTPUT_ISO): $(OVERLAY_PATH)/.disk/mkisofs | $(MBR_TEMPLATE)
	bash -x $< && ls -alh $@

DISK_VOL_SIZE=20G
.PRECIOUS: temp/%.img
temp/%.img: $(OUTPUT_ISO)
	mkdir -p $(dir $@)
	qemu-img create -f qcow2 $@ $(DISK_VOL_SIZE)


VNET_ID=85c389de-fba3-11ee-b252-4c77cbefdfc6
NETDEV_OPTS ?= -netdev user,id=net1,net=192.168.253.0/24,dhcpstart=192.168.253.9,dns=$$(grep '^nameserver' /etc/resolv.conf | awk '{print $$2}')
DEVICE_OPTS ?= -device virtio-net-pci,netdev=net1
VMINIT_OPTS ?= -vga virtio -smp 2 -m size=2G


.PHONY: qemu qemu-primary
qemu: qemu-primary qemu-secondary qemu-tertiary # qemu-quartiary
qemu-one: qemu-primary
qemu-primary: temp/disk1.img | $(OUTPUT_ISO)
	$(QEMU) -enable-kvm -name $(CODENAME) \
		-cdrom $(OUTPUT_ISO) $$(test $< -nt $(OUTPUT_ISO) || echo "-boot d") -hda $< \
		$(VMINIT_OPTS) $(NETDEV_OPTS) $(DEVICE_OPTS) \
		-daemonize

qemu-secondary: temp/disk2.img | $(OUTPUT_ISO)
	$(QEMU) -enable-kvm -name $(CODENAME) \
		-cdrom $(OUTPUT_ISO) $$(test $< -nt $(OUTPUT_ISO) || echo "-boot d") -hda $< \
		$(VMINIT_OPTS) $(NETDEV_OPTS) $(DEVICE_OPTS) \
		-daemonize

qemu-tertiary: temp/disk3.img | $(OUTPUT_ISO)
	$(QEMU) -enable-kvm -name $(CODENAME) \
		-cdrom $(OUTPUT_ISO) $$(test $< -nt $(OUTPUT_ISO) || echo "-boot d") -hda $< \
		$(VMINIT_OPTS) $(NETDEV_OPTS) $(DEVICE_OPTS) \
		-daemonize


qemu-quartiary: temp/disk4.img | $(OUTPUT_ISO)
	$(QEMU) -enable-kvm -name $(CODENAME) \
		-cdrom $(OUTPUT_ISO) $$(test $< -nt $(OUTPUT_ISO) || echo "-boot d") -hda $< \
		$(VMINIT_OPTS) $(NETDEV_OPTS) $(DEVICE_OPTS) \
		-daemonize


.PHONY: clean
clean:
	sudo rm -rf $(EXTRACT_PATH)  # NB: extracted paths may be read-only
	rm -rvf $(OVERLAY_PATH)/isolinux/*.cfg $(OVERLAY_PATH)/install/{preseed.*,*.cfg}
	rm -rvf $(OVERLAY_PATH)/.disk/mkisofs $(OVERLAY_PATH)/install.*/initrd.gz
	rm -rvf temp/disk*.img
	test \! -f $(OUTPUT_ISO) || rm -vf $(OUTPUT_ISO)


.DELETE_ON_ERROR: $(DEBIAN_ISO)

$(DEBIAN_ISO): # NB: URLs aren't safe dependencies
	wget --continue -O "$@" "$(DEBIAN_URL)"





