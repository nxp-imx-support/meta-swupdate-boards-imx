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

# Build imx-boot (which contains u-boot) and core-image-base before assembling
# the wic image. This ensures imx-boot.tagged is regenerated with the latest
# env-injected u-boot before the wic tool copies it into the SD card image.
IMAGE_DEPENDS = "core-image-base imx-boot"


IMAGE_FSTYPES += "wic wic.bmap"

# Add extra space for wic image if needed
IMAGE_ROOTFS_EXTRA_SPACE ?= "10240"

# ROOTFS_PART_SIZE (MiB) is computed dynamically in do_image_wic:prepend below.
# It is set to: ceil(IMAGE_ROOTFS_SIZE * IMAGE_OVERHEAD_FACTOR / 1 GiB) * 1024 MiB.
# Override here if you need a fixed minimum, e.g.:
#   ROOTFS_PART_SIZE = "2048"
# The default fallback (used if the prepend somehow does not run) is 1024 MiB.
ROOTFS_PART_SIZE ?= "1024"

# Compute ROOTFS_PART_SIZE from the actual rootfs size before wic assembles the
# image.  IMAGE_ROOTFS_SIZE (KiB) is available after do_rootfs completes.
# The result is rounded up to the next full GiB so the partition boundaries
# stay on 1 GiB multiples.
python do_image_wic:prepend() {
    import math
    rootfs_kib = int(d.getVar('IMAGE_ROOTFS_SIZE') or 0)
    if rootfs_kib <= 0:
        bb.warn("IMAGE_ROOTFS_SIZE is not set; using ROOTFS_PART_SIZE default")
        return
    overhead = float(d.getVar('IMAGE_OVERHEAD_FACTOR') or 1.3)
    needed_kib = int(math.ceil(rootfs_kib * overhead))
    # Round up to the nearest 1 GiB (1048576 KiB)
    gib_kib = 1024 * 1024
    size_kib = int(math.ceil(needed_kib / gib_kib)) * gib_kib
    size_mib = size_kib // 1024
    d.setVar('ROOTFS_PART_SIZE', str(size_mib))
    bb.note("ROOTFS_PART_SIZE: rootfs=%d KiB, overhead=%.2f -> partition=%d MiB" % (rootfs_kib, overhead, size_mib))
}
