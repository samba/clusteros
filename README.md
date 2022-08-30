# Bootable Virtualization Environment

The primary goal of this project is to simplify bootstrapping of hosts for virtualization and container orchestration.
In other words, I want to boot from bare metal to a host on which I can execute a virtual machine, or alternately, a bare host ready for provisioning into a Kubernetes cluster.

This project intentionally targets broad hardware compatibility.
I'm starting hardware I have at home. Some of it's older, but it's all i386 or amd64.
I use Debian most for server environments at home.

For virtualization I will rely on KVM.
For Kubernetes, I will use K0s, so the host can rely primarily on SSH with a pre-authorized key, and passwordless sudo.
(This is consistent with provisioning cloud hosts in Debian, that prepare the host with cloud-init.)


## Building the ISO

**Note** the Makefile is written to support only Linux hosts, for composing the ISO.
(I use a Debian VM on a MacOS laptop.)

```bash
make iso
make -e NEED_NONFREE_FIRMWARE=true iso
```



[repack]: https://wiki.debian.org/RepackBootableISO "repacking a Debian ISO"
[preseediso]: https://wiki.debian.org/DebianInstaller/Preseed/EditIso "Adding a preseed config to an ISO"
[debpreseed]: https://zauner.nllk.net/post/0033-debian-preseed/ "Preseeding Debian"
