# Kubernetes Bare Metal OS ("moss cube")

**This project is WORK IN PROGRESS**

Goal:  A simple and easy way to set up standalone  bare metal clusters.

The intended use of this project:

* Clone this repo
* Check the configuration in `debian/config/bootstrap.sh` and adjust to your needs
* Build your own ISO
* Write the ISO to a USB
* Install directly on all the machines you need.

## Platforms

This aims to support broad consumer-grade hardware compatibility, ease of use, stability and simplicity of deployment.

Therefore current efforts use Debian amd64. It's expected that with relatively little effort, the same kit could be adapted to support arm64. i386 is not officially supported by Kubernetes.

## Networking

* TODO home-network ease of use assumptions, necessary
* TODO required configuration inputs -- knowing first CP address, static IP, use of name alias
* TODO use of kube-vip

## Security

TODO: automatic encryption of the filesystem, TPM enrollment of the key
TODO: secure boot setup

To make setup relatively easier, a few security compromises have been accepted in this design.

* SSH keys, user passwords, Kubernetes "join tokens" and preliminary disk encryption keys are baked into the ISO and its preseed configuration.
* The default user has a random password, and pre-authorizes the keys generated during ISO build.
* The root user has a very long random password, but no authorized keys.
* The default user is permitted password-less sudo.

The ISO build  modifies numerous files and injects provisioning scripts, but does not *currently* update the checksum lists of the modified files. This makes it impossible to verify the ISO contents individually, after build.

Therefore, you really *SHOULD NOT* use an ISO produced by anyone else, if you don't want them to have access to your cluster. Instead, you should *always* build your own ISO for every new cluster.


## Storage

* TODO integrate CSI_LVM by default
* TODO integrate CSI_rclone by default
* TODO integrate CSI_NFS by default

## Building the ISO

**Note** the Makefile is written to support only Linux hosts, for composing the ISO.
The program `xorriso` is required. On MacOS, `colima` can provide a suitable Debian environment for building ISOs.


```bash
make -C debian iso
```



## Tenets

* The configuration of individual systems, in the ISO, should not require any context of the cluster topology, or individual host addresses or roles.


---

## Stuff to do...

- [ ] make automated install the default grub option in the ISO
- [ ] setup kubernetes stuff automatically across multiple hosts
- ... all the TODOs in the code


[repack]: https://wiki.debian.org/RepackBootableISO "repacking a Debian ISO"
[preseediso]: https://wiki.debian.org/DebianInstaller/Preseed/EditIso "Adding a preseed config to an ISO"
[debpreseed]: https://zauner.nllk.net/post/0033-debian-preseed/ "Preseeding Debian"



[1]: https://github.com/13pgeiser/debian_stable_preseed
[2]: https://github.com/mknj/simple-debian-docker-installer/blob/master/preseed.cfg
[3]: https://github.com/kubernetes-sigs/image-builder/blob/master/images/capi/packer/ova/linux/ubuntu/http/base/preseed.cfg
[4]: https://www.frakkingsweet.com/debian-preseed-and-docker/

