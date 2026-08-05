DESCRIPTION = "Example image demonstrating how to build SWUpdate compound image"

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

# images to build before building swupdate image
IMAGE_DEPENDS = "core-image-base"

# images and files that will be included in the .swu image
SWUPDATE_IMAGES = "core-image-base imx-boot-${MACHINE}-sd.bin-flash_singleboot"

SWUPDATE_IMAGES_FSTYPES[core-image-base] = ".rootfs.ext4.gz"
