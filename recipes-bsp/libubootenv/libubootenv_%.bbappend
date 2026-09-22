# fw_env.config lookup priority:
#   Yocto automatically searches <dir>/<MACHINE>/ before <dir>/ for each entry
#   in FILESEXTRAPATHS, so the resolution of "file://fw_env.config" is:
#   1. files/<MACHINE>/fw_env.config  -- machine-specific (highest priority)
#   2. files/fw_env.config            -- common fallback
#
# If the resolved fw_env.config is empty, fw_env.config is generated
# automatically from CONFIG_ENV_OFFSET and CONFIG_ENV_SIZE in the U-Boot defconfig:
#   line 1: <FW_ENV_DEV>  <ENV_OFFSET>          <ENV_SIZE>
#   line 2: <FW_ENV_DEV>  <ENV_OFFSET+ENV_SIZE>  <ENV_SIZE>  (redundant copy)
#
# To provide a hand-crafted fw_env.config for a machine, add content to:
#   files/<MACHINE>/fw_env.config
# Override FW_ENV_DEV if the eMMC device is not /dev/mmcblk0.
FW_ENV_DEV ?= "/dev/mmcblk0"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:class-target = " file://fw_env.config"

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

    # Static file is empty: auto-generate from U-Boot defconfig.
    defconfig=$(find ${TOPDIR}/../sources -name "${UBOOT_CONFIG_BASENAME}_defconfig" \
        -path "*/configs/*" 2>/dev/null | head -n 1)
    if [ -z "${defconfig}" ]; then
        bbwarn "libubootenv: ${UBOOT_CONFIG_BASENAME}_defconfig not found, fw_env.config will be empty"
        touch ${D}${sysconfdir}/fw_env.config
        return
    fi

    env_offset=$(grep -m1 '^CONFIG_ENV_OFFSET=' "${defconfig}" | sed 's/CONFIG_ENV_OFFSET=//; s/0[xX]//; s/"//g')
    env_size=$(grep -m1 '^CONFIG_ENV_SIZE=' "${defconfig}" | sed 's/CONFIG_ENV_SIZE=//; s/0[xX]//; s/"//g')

    if [ -z "${env_offset}" ] || [ -z "${env_size}" ]; then
        bbwarn "libubootenv: CONFIG_ENV_OFFSET/SIZE missing in ${defconfig}, fw_env.config will be empty"
        touch ${D}${sysconfdir}/fw_env.config
        return
    fi

    redund_offset=$(awk 'BEGIN { printf "0x%X\n", strtonum("0x'"${env_offset}"'") + strtonum("0x'"${env_size}"'") }')

    printf '%s\t0x%s\t0x%s\n' "${FW_ENV_DEV}" "${env_offset}" "${env_size}"   > ${D}${sysconfdir}/fw_env.config
    printf '%s\t%s\t0x%s\n'   "${FW_ENV_DEV}" "${redund_offset}" "${env_size}" >> ${D}${sysconfdir}/fw_env.config

    bbnote "libubootenv: auto-generated fw_env.config: offset=0x${env_offset} size=0x${env_size} redund=${redund_offset}"
}

FILES:${PN}:append:class-target = " ${sysconfdir}"
