FILESEXTRAPATHS:prepend := "${THISDIR}/files:${THISDIR}/${PN}:"

PACKAGECONFIG_CONFARGS = ""

# 09-swupdate-args has MACHINE substituted in, so the package is machine specific.
PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI += " \
    file://09-swupdate-args \
    file://swupdate-sysrestart.service \
    file://swupdate.cfg \
    file://swu_public.pem \
    file://sysinfo.cgi \
"

FILES:${PN} += " \
    ${systemd_system_unitdir}/swupdate-sysrestart.service \
"

# additional dependencies required to run swupdate on the target
RDEPENDS:${PN} += "u-boot-fw-utils"
RDEPENDS:${PN}-www += "bash"

SYSTEMD_SERVICE:${PN} += "swupdate-sysrestart.service"

do_install:append() {
    install -m 0644 ${UNPACKDIR}/09-swupdate-args ${D}${libdir}/swupdate/conf.d/
    sed -i "s#@MACHINE@#${MACHINE}#g" ${D}${libdir}/swupdate/conf.d/09-swupdate-args

    install -d ${D}${sysconfdir}
    install -m 644 ${UNPACKDIR}/swupdate.cfg ${D}${sysconfdir}
    install -m 644 ${UNPACKDIR}/swu_public.pem ${D}${sysconfdir}
    sed -i "s#@PUBKEY@#${sysconfdir}/swu_public.pem#g" ${D}${sysconfdir}/swupdate.cfg
    install -m 644 ${UNPACKDIR}/swupdate-sysrestart.service ${D}${systemd_system_unitdir}
    install -m 0755 ${UNPACKDIR}/sysinfo.cgi ${D}/www/sysinfo.cgi
}

