# fw_env.config lookup priority:
#   Yocto automatically searches <dir>/<MACHINE>/ before <dir>/ for each entry
#   in FILESEXTRAPATHS, so the resolution of "file://fw_env.config" is:
#   1. files/<MACHINE>/fw_env.config  -- machine-specific (highest priority)
#   2. files/fw_env.config            -- common fallback
#
# If the resolved fw_env.config is empty, fw_env.config is generated
# automatically from CONFIG_ENV_OFFSET and CONFIG_ENV_SIZE read from the
# U-Boot generated .config, which u-boot-imx installs into:
#   ${datadir}/u-boot/${UBOOT_CONFIG_BASENAME}.config
# That file is staged into the sysroot via the u-boot-imx-dev package and
# is available at ${STAGING_DATADIR}/u-boot/ during libubootenv do_install.
#
#   line 1: <FW_ENV_DEV>  <ENV_OFFSET>          <ENV_SIZE>
#   line 2: <FW_ENV_DEV>  <ENV_OFFSET+ENV_SIZE>  <ENV_SIZE>  (redundant copy)
#
# To provide a hand-crafted fw_env.config for a machine, add content to:
#   files/<MACHINE>/fw_env.config
# Override FW_ENV_DEV if the eMMC device is not /dev/mmcblk0.
FW_ENV_DEV ?= "/dev/mmcblk0"

# Board revision written to /etc/hwrevision; must match hardware-compatibility
# in sw-description.
SWU_HW_REV ?= "1.0"

# fw_env.config and hwrevision are machine specific.
PACKAGE_ARCH:class-target = "${MACHINE_ARCH}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:class-target = " file://fw_env.config"

# Depend on the u-boot-imx-dev package so that its staged .config is available
# in ${STAGING_DATADIR}/u-boot/ during do_install.
DEPENDS:append:class-target = " virtual/bootloader"

do_install:append:class-target() {
    echo "${MACHINE} ${SWU_HW_REV}" > ${WORKDIR}/hwrevision
    install -d ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/hwrevision ${D}${sysconfdir}

    static_cfg="${UNPACKDIR}/fw_env.config"

    if [ -s "${static_cfg}" ]; then
        # Static file has content: use it as-is.
        install -m 644 "${static_cfg}" ${D}${sysconfdir}/fw_env.config
        bbnote "libubootenv: using static fw_env.config for ${MACHINE}"
        return
    fi

    # Static file is empty: auto-generate from the U-Boot generated .config
    # staged by u-boot-imx-dev into ${STAGING_DATADIR}/u-boot/.
    staged_config="${STAGING_DATADIR}/u-boot/${UBOOT_CONFIG_BASENAME}.config"
    if [ ! -f "${staged_config}" ]; then
        bbwarn "libubootenv: ${staged_config} not found, fw_env.config will be empty"
        touch ${D}${sysconfdir}/fw_env.config
        return
    fi

    env_offset=$(grep -m1 '^CONFIG_ENV_OFFSET=' "${staged_config}" | sed 's/CONFIG_ENV_OFFSET=//; s/0[xX]//; s/"//g')
    env_size=$(grep -m1 '^CONFIG_ENV_SIZE=' "${staged_config}" | sed 's/CONFIG_ENV_SIZE=//; s/0[xX]//; s/"//g')

    if [ -z "${env_offset}" ] || [ -z "${env_size}" ]; then
        bbwarn "libubootenv: CONFIG_ENV_OFFSET/SIZE missing in ${staged_config}, fw_env.config will be empty"
        touch ${D}${sysconfdir}/fw_env.config
        return
    fi

    # Portable hex math (no gawk-only strtonum).
    off_dec=$(printf '%d' "0x${env_offset}")
    size_dec=$(printf '%d' "0x${env_size}")
    redund_offset=$(awk -v a="${off_dec}" -v b="${size_dec}" 'BEGIN { printf "0x%X", a + b }')

    printf '%s\t0x%s\t0x%s\n' "${FW_ENV_DEV}" "${env_offset}" "${env_size}"   > ${D}${sysconfdir}/fw_env.config
    printf '%s\t%s\t0x%s\n'   "${FW_ENV_DEV}" "${redund_offset}" "${env_size}" >> ${D}${sysconfdir}/fw_env.config

    bbnote "libubootenv: auto-generated fw_env.config from ${staged_config}: offset=0x${env_offset} size=0x${env_size} redund=${redund_offset}"
}

FILES:${PN}:append:class-target = " ${sysconfdir}"
