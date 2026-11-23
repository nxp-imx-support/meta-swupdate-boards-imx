DESCRIPTION = "Base image with A/B partition layout for SWUpdate OTA support"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit core-image
require swu-image.inc

# Use the unified wic layout from this layer.
# Partition table type is controlled by SWUPDATE_DISK_PTABLE:
#   "msdos" (default) -> MBR partition table
#   "gpt"             -> GUID Partition Table
# Override in local.conf or a machine conf:
#   SWUPDATE_DISK_PTABLE = "gpt"
SWUPDATE_DISK_PTABLE ?= "msdos"
WKS_FILE = "${THISDIR}/../../wic/imx-imx-boot-bootpart.wks.in"

# The wks file pulls imx-boot.tagged and the SWUpdate ramdisk from DEPLOY_DIR_IMAGE,
# so make sure both are built before wic assembles the image.
# (IMAGE_DEPENDS is only used by the swupdate class and has no effect here.)
do_image_wic[depends] += "${SWUPDATE_ROOTFS_IMAGE}:do_image_complete imx-boot:do_deploy swupdate-image:do_image_complete"

IMAGE_FSTYPES = "wic wic.bmap"

# Add extra space for wic image if needed
IMAGE_ROOTFS_EXTRA_SPACE ?= "10240"

#
# Derive SWUPDATE_ROOTFS_PART_SIZE from the generated rootfs image.
#
# This calculation is intended for workflows where the target image
# specified by SWUPDATE_ROOTFS_IMAGE has already been built, e.g.:
#
#   bitbake ${SWUPDATE_ROOTFS_IMAGE}
#   bitbake swu-base-image
#
# The partition size is calculated from the actual ext4 image size
# rather than IMAGE_ROOTFS_SIZE from this recipe, ensuring the A/B
# rootfs slots are sized according to the image being deployed.
#
# Calculation:
#
#   partition_size =
#       ceil(rootfs.ext4_size * 1.3 / 1 GiB) * 1024 MiB
#
# A 30% margin is added to accommodate future package growth and
# filesystem overhead. The final result is rounded up to the next
# GiB boundary.
#
# If SWUPDATE_ROOTFS_PART_SIZE is already defined (for example in
# local.conf), the user-specified value takes precedence and no
# automatic calculation is performed.
#
python () {
    import os
    import math

    if d.getVar('SWUPDATE_ROOTFS_PART_SIZE'):
        return

    image = d.getVar('SWUPDATE_ROOTFS_IMAGE')
    machine = d.getVar('MACHINE')
    deploy = d.getVar('DEPLOY_DIR_IMAGE')

    ext4 = os.path.join(
        deploy,
        "%s-%s.rootfs.ext4" % (image, machine)
    )

    if not os.path.exists(ext4):
        bb.warn(
            "Unable to calculate SWUPDATE_ROOTFS_PART_SIZE because %s "
            "does not exist. Build %s first or specify "
            "SWUPDATE_ROOTFS_PART_SIZE manually."
            % (ext4, image)
        )
        return

    size_mib = math.ceil(
        os.path.getsize(ext4) / 1024 / 1024
    )

    # Add 30% growth margin.
    size_mib = math.ceil(size_mib * 1.3)

    # Round up to a full GiB boundary.
    size_mib = math.ceil(size_mib / 1024) * 1024

    d.setVar('SWUPDATE_ROOTFS_PART_SIZE', str(size_mib))
}
