# swu-env.txt injection into the U-Boot board default environment.
#
# File layout under files/swu-env/:
#   env.txt                -- common variables for ALL machines (LOW priority)
#   <MACHINE>/env.txt      -- machine-specific variables (HIGH priority, optional)
#
# Priority: MACHINE-SPECIFIC > COMMON.
#
# Yocto automatically searches <dir>/<MACHINE>/ before <dir>/ for each entry
# in FILESEXTRAPATHS, so the resolution of "file://env.txt" is:
#   1. files/swu-env/<MACHINE>/env.txt  (machine-specific, higher priority)
#   2. files/swu-env/env.txt            (common fallback)
#
# To override a common variable for one machine, create:
#   files/swu-env/<MACHINE>/env.txt
# The common env.txt is only used when no machine-specific file is found.
#
# Injection method:
#   1. awk collapses backslash-continuation lines into single logical lines.
#   2. sed replaces each matching key=value in the board env file in-place,
#      or appends the line if the key is absent.
#   This handles multiline variables like mmcargs and bsp_bootcmd correctly.
#
# Board env file overlay (for boards that lack a .env in U-Boot source):
#   files/board-env/<MACHINE>/<sys_board>.env
#   If the U-Boot source tree has no matching .env file, the overlay is
#   copied into ${S}/board/<sys_vendor>/<sys_board>/ before injection.
FILESEXTRAPATHS:prepend := "${THISDIR}/files/swu-env:${THISDIR}/files:"

# Directory containing board .env overlays for boards that lack one in the
# U-Boot source tree.  Layout: <dir>/<MACHINE>/<sys_board>.env
UBOOT_BOARD_ENV_OVERLAY_DIR = "${THISDIR}/files/board-env"

# Yocto resolves env.txt from <MACHINE>/ first, then falls back to the common file.
SRC_URI += "file://env.txt"

# PACKAGE_BEFORE_PN += "${PN}-env" is intentionally omitted: u-boot.inc line 248
# already adds ${PN}-env to PACKAGES. Repeating it causes a QA error:
#   "u-boot-imx-env is listed in PACKAGES multiple times"
RPROVIDES:${PN}-env += "u-boot-default-env"

# Install the final .config (after Kconfig injection) into datadir so that
# libubootenv can read CONFIG_ENV_OFFSET and CONFIG_ENV_SIZE from the staging
# sysroot, without searching the build work tree at install time.
# The file is staged via the -dev package and consumed by libubootenv DEPENDS.
do_install:append() {
    dot_config="${B}/${UBOOT_CONFIG_BASENAME}_defconfig/.config"
    if [ -f "${dot_config}" ]; then
        install -d "${D}${datadir}/u-boot"
        install -m 644 "${dot_config}" "${D}${datadir}/u-boot/${UBOOT_CONFIG_BASENAME}.config"
        bbnote "u-boot-imx: staged ${dot_config} -> ${D}${datadir}/u-boot/${UBOOT_CONFIG_BASENAME}.config"
    else
        bbwarn "u-boot-imx: .config not found at ${dot_config}, skipping datadir install"
    fi
}

FILES:${PN}-dev += "${datadir}/u-boot"

do_configure:append() {
    # Inject SWUpdate-required Kconfig options into the generated .config.
    # CONFIG_ENV_OFFSET_REDUND is computed as CONFIG_ENV_OFFSET + CONFIG_ENV_SIZE.
    # This block runs after "make <defconfig>" has produced .config, so the
    # values are read from the real generated config rather than the defconfig.
    dot_config_kconfig="${B}/${UBOOT_CONFIG_BASENAME}_defconfig/.config"
    if [ -f "${dot_config_kconfig}" ]; then
        env_offset=$(grep -m1 '^CONFIG_ENV_OFFSET=' "${dot_config_kconfig}" | sed 's/CONFIG_ENV_OFFSET=//; s/0x//; s/"//g')
        env_size=$(grep -m1 '^CONFIG_ENV_SIZE=' "${dot_config_kconfig}" | sed 's/CONFIG_ENV_SIZE=//; s/0x//; s/"//g')
        if [ -n "${env_offset}" ] && [ -n "${env_size}" ]; then
            redund_offset=$(awk 'BEGIN { printf "0x%X\n", strtonum("0x'"${env_offset}"'") + strtonum("0x'"${env_size}"'") }')
            bbnote "u-boot-imx: CONFIG_ENV_OFFSET=0x${env_offset} + CONFIG_ENV_SIZE=0x${env_size} -> CONFIG_ENV_OFFSET_REDUND=${redund_offset}"
        else
            bbwarn "u-boot-imx: could not read CONFIG_ENV_OFFSET or CONFIG_ENV_SIZE, skipping redundant env config"
            redund_offset=""
        fi

        # Helper: set or replace a CONFIG_ line in .config.
        set_config() {
            local cfg="$1"
            local val="$2"
            local file="$3"
            if grep -q "^${cfg}=" "${file}" || grep -q "^# ${cfg} is not set" "${file}"; then
                sed -i "s|^${cfg}=.*|${cfg}=${val}|; s|^# ${cfg} is not set|${cfg}=${val}|" "${file}"
            else
                printf '%s=%s\n' "${cfg}" "${val}" >> "${file}"
            fi
        }

        set_config CONFIG_SYS_REDUNDAND_ENVIRONMENT y   "${dot_config_kconfig}"
        set_config CONFIG_BOOTCOUNT_LIMIT            y   "${dot_config_kconfig}"
        set_config CONFIG_BOOTCOUNT_ENV              y   "${dot_config_kconfig}"
        set_config CONFIG_BOOTCOUNT_BOOTLIMIT        3   "${dot_config_kconfig}"
        if [ -n "${redund_offset}" ]; then
            set_config CONFIG_ENV_OFFSET_REDUND "${redund_offset}" "${dot_config_kconfig}"
        fi
        bbnote "u-boot-imx: injected redundant env and bootcount configs into ${dot_config_kconfig}"
    else
        bbwarn "u-boot-imx: .config not found at ${dot_config_kconfig}, skipping kconfig injection"
    fi

    active_env="${UNPACKDIR}/env.txt"

    if [ ! -s "${active_env}" ]; then
        bbnote "u-boot-imx: env.txt is empty, skipping injection"
        return
    fi

    # Locate the board env file using the generated .config (produced after
    # do_configure runs).  The .config lives under a per-config subdirectory:
    #   ${B}/${UBOOT_CONFIG_BASENAME}/.config
    # Priority: CONFIG_ENV_SOURCE_FILE > CONFIG_SYS_BOARD.
    # If neither yields a file, check the layer overlay directory
    # (${UBOOT_BOARD_ENV_OVERLAY_DIR}/<sys_vendor>/<sys_board>/<sys_board>.env)
    # and copy it into the U-Boot source tree before injecting.
    board_env=""
    dot_config="${B}/${UBOOT_CONFIG_BASENAME}_defconfig/.config"
    if [ -f "${dot_config}" ]; then
        env_source=$(grep -m1 '^CONFIG_ENV_SOURCE_FILE=' "${dot_config}" | sed 's/CONFIG_ENV_SOURCE_FILE=//; s/"//g')
        if [ -n "${env_source}" ]; then
            board_env=$(find "${S}/board" -maxdepth 3 -name "${env_source}.env" 2>/dev/null | head -n 1)
            bbnote "u-boot-imx: CONFIG_ENV_SOURCE_FILE=${env_source}, board_env=${board_env}"
        else
            sys_board=$(grep -m1 '^CONFIG_SYS_BOARD=' "${dot_config}" | sed 's/CONFIG_SYS_BOARD=//; s/"//g')
            sys_vendor=$(grep -m1 '^CONFIG_SYS_VENDOR=' "${dot_config}" | sed 's/CONFIG_SYS_VENDOR=//; s/"//g')
            if [ -n "${sys_board}" ]; then
                board_env=$(find "${S}/board" -maxdepth 3 -name "${sys_board}.env" 2>/dev/null | head -n 1)
                bbnote "u-boot-imx: CONFIG_SYS_BOARD=${sys_board}, board_env=${board_env}"
            fi
        fi
    else
        bbnote "u-boot-imx: .config not found at ${dot_config}, skipping env injection"
        return
    fi

    # If no .env found in the U-Boot source tree, check the layer overlay.
    # Overlay layout: files/board-env/<MACHINE>/<sys_board>.env
    if [ -z "${board_env}" ] && [ -n "${sys_board}" ]; then
        overlay_env="${UBOOT_BOARD_ENV_OVERLAY_DIR}/${MACHINE}/${sys_board}.env"
        if [ -f "${overlay_env}" ]; then
            dest_dir="${S}/board/${sys_vendor}/${sys_board}"
            if [ -d "${dest_dir}" ]; then
                cp "${overlay_env}" "${dest_dir}/${sys_board}.env"
                board_env="${dest_dir}/${sys_board}.env"
                bbnote "u-boot-imx: installed overlay env ${overlay_env} -> ${board_env}"
            else
                bbwarn "u-boot-imx: overlay env found but board dir ${dest_dir} does not exist, skipping"
            fi
        fi
    fi

    if [ -z "${board_env}" ]; then
        bbnote "u-boot-imx: no board env file found, skipping injection"
        return
    fi

    bbnote "u-boot-imx: applying ${active_env} overrides to ${board_env}"

    # join_lines: collapse backslash-continuation lines into single logical lines.
    join_lines() {
        awk '{
            if (sub(/\\$/, "")) {
                printf "%s", $0
            } else {
                print
            }
        }' "$1"
    }

    joined_src="${active_env}.joined"
    joined_dst="${board_env}.joined"
    join_lines "${active_env}" > "${joined_src}"
    join_lines "${board_env}"  > "${joined_dst}"

    while IFS= read -r line; do
        # Skip blank lines and comment lines.
        case "${line}" in ''|\#*) continue ;; esac

        key="${line%%=*}"
        value="${line#*=}"

        # Escape characters special in sed replacement: backslash, ampersand,
        # and the separator (|) used in the s command below.
        esc_value=$(printf '%s\n' "${value}" | sed 's/\\/\\\\/g; s/&/\\&/g; s/|/\\|/g')

        if grep -q "^${key}=" "${joined_dst}"; then
            sed -i "s|^${key}=.*|${key}=${esc_value}|" "${joined_dst}"
            bbnote "u-boot-imx: replaced  ${key}"
        else
            printf '%s\n' "${line}" >> "${joined_dst}"
            bbnote "u-boot-imx: appended  ${key}"
        fi
    done < "${joined_src}"

    mv "${joined_dst}" "${board_env}"
    rm -f "${joined_src}"
}
