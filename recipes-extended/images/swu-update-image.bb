DESCRIPTION = "SWUpdate compound image with A/B slot support"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit swupdate
require swu-image.inc

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

# IMAGE_DEPENDS is consumed by swupdate_getdepends() to add do_build
# dependencies, so it must list the rootfs image recipe.
IMAGE_DEPENDS = "${SWUPDATE_ROOTFS_IMAGE}"

# Images and files that will be included in the .swu archive.
SWUPDATE_IMAGES = "${SWUPDATE_ROOTFS_IMAGE} imx-boot"

# varflag keys do not support variable expansion in BitBake, so these lines
# must use the literal recipe name that matches SWUPDATE_ROOTFS_IMAGE above.
#SWUPDATE_IMAGES_FSTYPES[${SWUPDATE_ROOTFS_IMAGE}] = ".rootfs.ext4.gz"
# Use __anonymous function to create varflag in runtime
python __anonymous() {
    img = d.getVar("SWUPDATE_ROOTFS_IMAGE")
    d.setVarFlag("SWUPDATE_IMAGES_FSTYPES",
                 img,
                 ".rootfs.ext4.gz")
}

# imx-boot is deployed as a plain "imx-boot" symlink (no MACHINE suffix).
# Setting NOAPPEND_MACHINE to "1" tells the bbclass to search for "imx-boot"
# instead of "imx-boot-<MACHINE>".  No fstype entry needed for a binary file.
SWUPDATE_IMAGES_NOAPPEND_MACHINE[imx-boot] = "1"

SWU_BOOTPART_DEV ?= "/dev/mmcblk0boot0"
SWU_BOOTPART_OFFSET ?= "${@get_swu_bootpart_offset(d)}"
