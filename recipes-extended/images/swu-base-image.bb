DESCRIPTION = "Base image with A/B partition layout for SWUpdate OTA support"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit core-image

# Use the unified wic layout from this layer.
# Partition table type is controlled by DISK_PTABLE:
#   "msdos" (default) -> MBR partition table
#   "gpt"             -> GUID Partition Table
# Override in local.conf or a machine conf:
#   DISK_PTABLE = "gpt"
DISK_PTABLE ?= "msdos"
WKS_FILE = "${THISDIR}/../../wic/imx-imx-boot-bootpart.wks.in"

# The wks file pulls imx-boot.tagged and the SWUpdate ramdisk from DEPLOY_DIR_IMAGE,
# so make sure both are built before wic assembles the image.
# (IMAGE_DEPENDS is only used by the swupdate class and has no effect here.)
do_image_wic[depends] += "imx-boot:do_deploy swupdate-image:do_image_complete"


IMAGE_FSTYPES += "wic wic.bmap"

# Add extra space for wic image if needed
IMAGE_ROOTFS_EXTRA_SPACE ?= "10240"

# ROOTFS_PART_SIZE (MiB) for each rootfs slot, rounded up to a full GiB:
#   ceil(IMAGE_ROOTFS_SIZE * IMAGE_OVERHEAD_FACTOR / 1 GiB) * 1024
# Computed at parse time because the .wks.in template is expanded before
# do_image_wic runs; setting it inside do_image_wic would be too late.
# Set ROOTFS_PART_SIZE in local.conf to force a fixed size instead.
python () {
    import math
    if d.getVar('ROOTFS_PART_SIZE'):
        return
    rootfs_kib = int(d.getVar('IMAGE_ROOTFS_SIZE') or 0)
    overhead = float(d.getVar('IMAGE_OVERHEAD_FACTOR') or 1.3)
    gib_kib = 1024 * 1024
    needed = max(int(math.ceil(rootfs_kib * overhead)), 1)
    size_mib = int(math.ceil(needed / gib_kib)) * 1024
    d.setVar('ROOTFS_PART_SIZE', str(size_mib))
}
