FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:class-target = " file://fw_env.config"

do_install:append:class-target() {
    echo "${MACHINE} ${SWU_HW_REV}" > ${WORKDIR}/hwrevision
	install -d ${D}${sysconfdir}
	install -m 644 ${UNPACKDIR}/fw_env.config ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/hwrevision    ${D}${sysconfdir}
}

FILES:${PN}:append:class-target = " ${sysconfdir}"
