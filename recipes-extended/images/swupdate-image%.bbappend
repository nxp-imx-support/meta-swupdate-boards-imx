IMAGE_INSTALL = "base-files \
		base-passwd \
		busybox \
		mtd-utils \
		mtd-utils-ubifs \
		libconfig \
		swupdate \
		swupdate-www \
                ${@bb.utils.contains('SWUPDATE_INIT', 'tiny', 'virtual/initscripts-swupdate', 'initscripts systemd', d)} \
		util-linux-sfdisk \
		mmc-utils \
		e2fsprogs-resize2fs \
		lua \
		 "

# Only the U-Boot wrapped cpio is used: the wks file raw-copies
# swupdate-image-${MACHINE}.rootfs.cpio.gz.u-boot to the ramdisk area.
IMAGE_FSTYPES = "cpio.gz.u-boot"

PACKAGE_EXCLUDE += "jailhouse kernel-module-jailhouse libncursesw5 libpanelw5 libpython3 python3* perl* apt dpkg"
