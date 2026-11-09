DESCRIPTION = "SWUpdate compound image with A/B slot support"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit swupdate

# Sign sw-description with RSA private key so swupdate can verify the package.
# SWUPDATE_SIGNING = "RSA" causes the bbclass to run:
#   openssl dgst -sha256 -sign <key> -out sw-description.sig sw-description
# and prepend sw-description.sig to the cpio archive right after sw-description.
SWUPDATE_SIGNING = "RSA"

# The in-layer key pair is a DEMO key only. Anyone with access to this layer
# can sign a valid .swu with it. For production, keep the private key outside
# the layer and override these in local.conf or a distro conf, e.g.:
#   SWUPDATE_PRIVATE_KEY = "/secure/path/priv.pem"
#   SWUPDATE_PASSWORD_FILE = "/secure/path/swupdate-key.pass"
SWU_DEMO_KEY_DIR = "${THISDIR}/../../recipes-support/swupdate/swupdate"
SWUPDATE_PRIVATE_KEY ?= "${SWU_DEMO_KEY_DIR}/priv.pem"
SWUPDATE_PASSWORD_FILE ?= "${SWU_DEMO_KEY_DIR}/swupdate-key.pass"

python () {
    import os
    key = os.path.realpath(d.getVar('SWUPDATE_PRIVATE_KEY') or '')
    demo = os.path.realpath(os.path.join(d.getVar('SWU_DEMO_KEY_DIR'), 'priv.pem'))
    if key == demo:
        bb.warn("swu-update-image: signing with the in-layer DEMO private key. "
                "Set SWUPDATE_PRIVATE_KEY outside the layer for production.")
}

SRC_URI = "\
    file://emmcsetup.lua \
    file://sw-description \
"

# The rootfs image recipe to package into the .swu file.
# @@ROOTFS_IMAGE@@ in sw-description is substituted with this value by the
# swupdate bbclass via swupdate_expand_bitbake_variables().
# Changing ROOTFS_IMAGE here is the only edit needed when switching the rootfs.
ROOTFS_IMAGE = "core-image-base"

# IMAGE_DEPENDS is consumed by swupdate_getdepends() to add do_build
# dependencies, so it must list the rootfs image recipe.
IMAGE_DEPENDS = "${ROOTFS_IMAGE}"

# Images and files that will be included in the .swu archive.
SWUPDATE_IMAGES = "${ROOTFS_IMAGE} imx-boot"

# varflag keys do not support variable expansion in BitBake, so these lines
# must use the literal recipe name that matches ROOTFS_IMAGE above.
SWUPDATE_IMAGES_FSTYPES[core-image-base] = ".rootfs.ext4.gz"

# imx-boot is deployed as a plain "imx-boot" symlink (no MACHINE suffix).
# Setting NOAPPEND_MACHINE to "1" tells the bbclass to search for "imx-boot"
# instead of "imx-boot-<MACHINE>".  No fstype entry needed for a binary file.
SWUPDATE_IMAGES_NOAPPEND_MACHINE[imx-boot] = "1"

# Bootloader target: eMMC boot0 hardware partition. emmcsetup.lua unlocks
# force_ro in preinst and runs "mmc bootpart enable 1 1" in postinst so the
# ROM boots from boot0. Bootloader offset by SoC:
#   1K  - i.MX 6, i.MX 7
#   33K - i.MX 8QuadMax A0, i.MX 8QuadXPlus A0, i.MX 8M Quad, i.MX 8M Mini
#   32K for User partition and 0K for Boot partition - i.MX 8QuadXPlus B0,
#         i.MX 8QuadMax B0, i.MX 8DualX, i.MX 8DXL,
#         i.MX 8M Nano, i.MX 8M Plus, i.MX 8ULP, i.MX 9
# The BSP machine configs already set IMX_BOOT_SEEK (in KiB) to 32 or 33 per
# the table above, so reuse it. i.MX 6/7 machines do not define it: use 1K.
# Override SWU_BOOTPART_OFFSET in local.conf or a machine conf if needed.
# Referenced in sw-description as @@SWU_BOOTPART_DEV@@ / @@SWU_BOOTPART_OFFSET@@.
def get_swu_bootpart_offset(d):
    import re

    dev = d.getVar('SWU_BOOTPART_DEV') or ""
    seek = d.getVar('IMX_BOOT_SEEK') or "1"

	# boot from emmc boot partition, return 0K for iMX9, iMX8MP, iMX8MN, iMX8QXP, iMX8QM, IMX8ULP
    if re.search(r"mmcblk\d+boot\d+$", dev) and seek == "32":
        return "0K"

    return seek + "K"

SWU_BOOTPART_DEV ?= "/dev/mmcblk0boot0"
SWU_BOOTPART_OFFSET ?= "${@get_swu_bootpart_offset(d)}"
