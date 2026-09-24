DESCRIPTION = "SWUpdate compound image with A/B slot support"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit swupdate

# Sign sw-description with RSA private key so swupdate can verify the package.
# SWUPDATE_SIGNING = "RSA" causes the bbclass to run:
#   openssl dgst -sha256 -sign <key> -out sw-description.sig sw-description
# and prepend sw-description.sig to the cpio archive right after sw-description.
SWUPDATE_SIGNING = "RSA"
SWUPDATE_PRIVATE_KEY = "${THISDIR}/../../recipes-support/swupdate/swupdate/priv.pem"
SWUPDATE_PASSWORD_FILE = "${THISDIR}/../../recipes-support/swupdate/swupdate/swupdate-key.pass"

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
