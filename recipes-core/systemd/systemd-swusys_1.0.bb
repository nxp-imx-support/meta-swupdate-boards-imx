SUMMARY = "SWUpdate boot status helper"
DESCRIPTION = "systemd service that clears upgrade_available and bootcount after a successful boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://clrupstatus.service"

S = "${UNPACKDIR}"

inherit systemd

SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "clrupstatus.service"

RDEPENDS:${PN} += "libubootenv-bin"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/clrupstatus.service ${D}${systemd_system_unitdir}/
}
